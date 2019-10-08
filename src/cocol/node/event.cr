require "http/web_socket"

require "./event/repo"

require "./messenger/repo"
require "./ledger/repo"

require "./event/api.cr"

module Event
  extend self

  # should be Enum
  alias EventType = String
  alias TransactionEvent = NamedTuple
  alias PeerConnectionEvent = NamedTuple
  alias NewBlockEvent = NamedTuple

  def add_socket(socket : HTTP::WebSocket)
    Event::Repo.websockets << socket
  end

  def del_socket(socket : HTTP::WebSocket)
    Event::Repo.websockets.delete(socket)
  end

  def broadcast(payload : String)
    Event::Repo.websockets.each do |socket|
      socket.send payload
    end
  end

  def update(event : String) : NamedTuple
    update = {
      event: event,
      peers: Messenger::Repo.peers.map { |peer| peer.handshake.port },
      port:  Node.settings.port,
      miner: Node.settings.miner,
    }

    latest_block = Ledger::Repo.blocks[Ledger::Repo.latest_block_hash]
    update = update.merge({
      height: latest_block.height,
      hash:   latest_block.hash,
    })

    update
  end

  def transaction(event : EventType,
                  transaction : Ledger::Model::Transaction) : TransactionEvent
    {
      event:  event,
      hash:   transaction.hash,
      amount: transaction.amount,
    }
  end

  def peer(peer : Messenger::Struct::Peer) : PeerConnectionEvent
    {
      event:     "onConnection",
      node_port: Node.settings.port,
      peer_port: peer.handshake.port,
    }
  end

  def block(block : Ledger::Model::Block) : NewBlockEvent
    {
      event:         "onNewBlock",
      hash:          block.hash,
      previous_hash: block.previous_hash,
      height:        block.height,
    }
  end
end
