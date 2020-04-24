# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at # http://mozilla.org/MPL/2.0/

require "./event/**"
require "./messenger"
require "./ledger"

module Event
  extend self

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
      event:  event,
      peers:  Messenger::Repo.peers.map { |peer| {port: peer.port, host: peer.host, ident: peer.ident} },
      port:   Node.settings.port,
      miner:  Node.settings.miner,
      host:   Node.settings.host,
      ident:  Node.settings.ident,
      name:   Node.settings.name,
      master: Node.settings.master,
    }

    latest_block = Ledger::Repo.blocks[Ledger::Util.probfin_tip_hash]
    update = update.merge({
      height: latest_block.height,
      hash:   latest_block.hash,
    })

    update
  end

  def transaction(
    event : EventType,
    transaction : Ledger::Action::Transaction
  ) : TransactionEvent
    {
      event:  event,
      hash:   transaction.hash,
      amount: transaction.amount,
    }
  end

  def peer(peer : Messenger::Struct::Peer) : PeerConnectionEvent
    {
      event: "onConnection",
      node:  {ident: Node.settings.ident, master: Node.settings.master},
      peer:  {ident: peer.ident, host: peer.host, port: peer.port},
    }
  end

  def block(
    block : Ledger::Block::Abstract
  ) : NewBlockEvent
    {
      event:         "onNewBlock",
      hash:          block.hash,
      previous_hash: block.previous_hash,
      height:        block.height,
    }
  end
end
