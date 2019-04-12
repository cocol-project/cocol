var nodes = [
  {
    port: '3000',
    peers: []
  }
];

var transactions = {};

var blocks = {
  // Genesis block
  0: [
    {
      hash: '00f82f15d9fee292860b2a37183d769efd3b617451c04017f700238fd472e8bb',
      previous_hash: 'Olivia'
    }
  ]
};

var stats = new Vue({
  el: '#stats-list',
  data: {transactions: transactions}
});

var chain = new Vue({
  el: '#blocks',
  data: {blocks: blocks}
});

var graph = Viva.Graph.graph();
var graphics = Viva.Graph.View.svgGraphics();
var nodeSize = 24;


var loopNodes = function () {
  for (i=0; i < nodes.length; ++i) {
    (function () {
      var currentIndex = i;
      if (!nodes[i].socket) {
        connectToNode(currentIndex);
      }
    }());
  }
};

var connectToNode = function (i) {
  socket = new WebSocket('ws://localhost:'+nodes[i].port+'/events');
  socket.addEventListener('message', function (event) {
    console.log('===== now event ======');
    var eventData = JSON.parse(event.data);
    processEvent(eventData, i);
  });
  socket.addEventListener('close', function (event) {
    console.log('===== now closing ======');
    url = new URL(event.target.url);
    removeNode(url.port);
  });
  nodes[i].socket = socket;
};

var processEvent = function (event, i) {
  console.log('> process event');
  if (event.event === 'onTxn') {
    console.log('> + new txn');
    transactions[event.hash] = event.amount;
    stats.transactions = transactions;
    stats.$forceUpdate();
  } else if(event.event === 'onConnection') {
      console.log('> + new peer');
      checkConnections([event.peer_port], event.node_port);
  } else if(event.event === 'onNewBlock') {
    console.log('> + new block');
    if (!blocks[event.height]) {
      blocks[event.height] = [];
    }
    blocks[event.height].push({hash: event.hash, previous_hash: event.previous_hash});
    chain.blocks = blocks;
    chain.$forceUpdate();
  } else {
    // this we only do because we don't know the master node ident
    console.log('> + new node');
    nodes[i].height = event.height;
    nodes[i].hash = event.hash;
    nodes[i].peers = event.peers;
    nodes[i].port = event.port;
    nodes[i].txn = event.txn;
    nodes[i].miner = event.miner;

    if (nodes[i].port !== '3000' && nodes[i].port !== 3000) {
      graph.addNode(nodes[i].port, {
        height: nodes[i].height,
        hash: nodes[i].hash || '-',
        txn: nodes[i].txn || 0,
        miner: nodes[i].miner
      });
    }

    if (event.event === 'onInitialUpdate') {
      checkConnections(event.peers, nodes[i].port);
    }
  }
};

var checkConnections = function (peers, parentApiPort) {
  for (i=0; i < peers.length; ++i) {
    (function () {
      var peer = nodes.find(node => node.port === peers[i]);
      if (!peer) {
        nodes.push({port: peers[i]});
        stats.nodes = nodes;
        connectToNode(nodes.length - 1);
      }
      // also create link
      if (parentApiPort !== '3000' && parentApiPort !== 3000) {
        if (graph.getLink(peers[i], parentApiPort) === null && graph.getLink(parentApiPort, peers[i]) === null) {
          graph.addLink(peers[i], parentApiPort);
        }
      }
    }());
  }
};

var removeNode = function (port) {
  graph.removeNode(port);
  nodes = nodes.filter(node => parseInt(port) !== node.port);
  stats.nodes = nodes;
};

loopNodes();

graphics.node(function(node) {
  // This time it's a group of elements: http://www.w3.org/TR/SVG/struct.html#Groups
  var ui = Viva.Graph.svg('g');
      // Create SVG text element with user id as content
  var stringToColour = function(str) {
    var hash = 0;
    for (var i = 0; i < str.length; i++) {
      hash = str.charCodeAt(i) + ((hash << 5) - hash);
    }
    var colour = '#';
    for (var i = 0; i < 3; i++) {
      var value = (hash >> (i * 8)) & 0xFF;
      colour += ('00' + value.toString(16)).substr(-2);
    }
    return colour;
  };
  var height = node.data ? node.data.height : '0';
  var hash = node.data ? node.data.hash : '-';

  var svgText = Viva.Graph.svg('text').attr('y', '-4px').text(node.id+' / '+height+' / '+hash.substr(-6));
  var svgCircle = Viva.Graph.svg('circle')
      .attr('r', '7px')
      .attr('cy', '12')
      .attr('cx', '12')
      .attr('fill', stringToColour(hash));

  if ( node.data && node.data.miner === true ) {
    svgCircle = svgCircle.attr('stroke', '#ff6859').attr('stroke-width', 3);
  }

  ui.append(svgText);
  ui.append(svgCircle);

  return ui;
}).placeNode(function(nodeUI, pos) {
  // 'g' element doesn't have convenient (x,y) attributes, instead
  // we have to deal with transforms: http://www.w3.org/TR/SVG/coords.html#SVGGlobalTransformAttribute
  nodeUI.attr('transform',
              'translate(' +
              (pos.x - nodeSize/2) + ',' + (pos.y - nodeSize/2) +
              ')');
});

graphics.link(function(link){
  return Viva.Graph.svg('line')
    .attr('stroke', 'rgba(0,0,0,0.1)')
    .attr('stroke-width', 1);
});
var layout = Viva.Graph.Layout.forceDirected(graph, {
  springLength: 300
});
var renderer = Viva.Graph.View.renderer(graph, {
  layout: layout,
  graphics : graphics,
  container: document.getElementById('graph')
});

renderer.run();

// ============================================================================
