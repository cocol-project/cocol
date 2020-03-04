# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at # http://mozilla.org/MPL/2.0/

require "./messenger/**"

module Messenger
  extend self

  module Action
    module Base
      extend self

      def broadcast(to endpoint : String, body : String) : Void
        Messenger::Repo.peers.each do |peer|
          uri = peer_uri(from: peer)
          uri.path = endpoint
          post(to: uri, body: body)
        end
      end

      def post(
        to uri : URI,
        body : String
      ) : HTTP::Client::Response | Nil
        client = HTTP::Client.new(uri)
        begin
          response = client.post(
            path: uri.path,
            headers: HTTP::Headers{
              "Content-Type" => "application/json",
              "X-Node-Id"    => Node.settings.ident.to_s,
            },
            body: body
          )
          client.close
          response
        rescue
          Cocol.logger.warn "Peer is not responding at POST-#{uri}"
          nil
        end
      end

      def get(from uri : URI) : HTTP::Client::Response | Nil
        client = HTTP::Client.new(uri)
        begin
          response = client.get(
            path: uri.path,
            headers: HTTP::Headers{
              "Content-Type" => "application/json",
              "X-Node-Id"    => Node.settings.ident.to_s,
            }
          )
          client.close
          response
        rescue
          Cocol.logger.warn "Peer is not responding at GET-#{uri}"
          nil
        end
      end

      def peer_uri(from peer : Messenger::Struct::Peer) : URI
        URI.new(
          scheme: "http",
          host: peer.host,
          port: peer.port.to_i32
        )
      end
    end

    module PropagateTransaction
      include Base
      extend self

      PATH = "/transactions"

      def call(payload : Ledger::Action::Transaction)
        broadcast to: PATH, body: payload.to_json
      end
    end

    module Handshake
      include Base
      extend self

      PATH = "/peers"

      def call(peer : Messenger::Struct::Peer) : HTTP::Client::Response | Nil
        payload = Messenger::Struct::Peer.new(**Node.settings.peer_info)
        uri = peer_uri(from: peer)
        uri.path = PATH
        post(to: uri, body: payload.to_json)
      end
    end

    module GetPeers
      include Base
      extend self

      PATH = "/peers"

      def call(peer : Messenger::Struct::Peer) : Array(Messenger::Struct::Peer)
        uri = peer_uri(from: peer)
        uri.path = PATH
        response = get(from: uri)
        # TODO: fixme, this is bad https://gph.is/2drwobJ
        return Array(Messenger::Struct::Peer).new if response.nil?
        Array(Messenger::Struct::Peer).from_json(response.body)
      end
    end

    module GetBlock
      include Base
      extend self

      PATH = "/blocks/:hash"

      def call(block_hash : String, peer : Messenger::Struct::Peer) : Ledger::Block::Pow
        uri = peer_uri(from: peer)
        uri.path = PATH.gsub(":hash", block_hash)
        response = get(from: uri)
        Ledger::Block::Pow.from_json(response.as(HTTP::Client::Response).body)
      end
    end

    module Inventory
      extend self
      include Base
      include Ledger::Block

      PATH = "/inventory/:best_hash"

      def call(peer : Messenger::Struct::Peer, best_hash : BlockHash) : Array(BlockHash)
        uri = peer_uri(from: peer)
        uri.path = PATH.gsub(":best_hash", best_hash)
        response = get(from: uri)

        Array(BlockHash).from_json(response.as(HTTP::Client::Response).body)
      end
    end
  end

  def establish_network_position
    config = Totem.from_file("./config.yml")
    master = config.mapping(Messenger::Struct::Peer, "master")

    # make yourself known
    Messenger::Action::Handshake.call peer: master

    # now get all peers master knows about
    peers = Messenger::Action::GetPeers.call(peer: master)
    # remove yourself
    peers = peers.reject! { |p| p.ident == Node.settings.ident }
    Messenger::Repo.known_peers.concat(peers)

    # now establish connection to peers if free slots are available
    peers.sample(Messenger.free_slots).each do |peer|
      sleep 1
      next if Node.settings.ident == peer.ident
      next if (handshake = Messenger::Action::Handshake.call(peer)).nil?
      next if handshake.status_code != 200

      Messenger::Repo.peers.add(peer)
    end
  end

  def free_slots : UInt16
    free = Node.settings.max_connections - Messenger::Repo.peers.size
    return 0_u16 if free < 0
    free.to_u16
  end
end
