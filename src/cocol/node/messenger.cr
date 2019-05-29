require "http/client"

require "./messenger/struct/handshake"
require "./messenger/struct/peer"

require "./messenger/repo"

require "./ledger"
require "./ledger/model/transaction"

require "./settings"

require "./messenger/api.cr"

module Messenger
  extend self

  def handshake(with client : HTTP::Client) : HTTP::Client::Response
    client.post(
      "/peers",
      headers: HTTP::Headers{"Content-Type" => "application/json"},
      body: Messenger::Struct::Handshake.new(
        ident: Node.settings.ident,
        port: Node.settings.port
      ).to_json
    )
  end

  # This is more of an e2e test
  def establish_network_position
    # TODO: totem broke with crystal 0.28.0
    # config = Totem.from_file("/home/cris/Projects/crystal/cocol/config.yml")
    # master = config.get("master").as_h
    master = {"host" => "localhost", "port" => 3000}

    master = HTTP::Client.new(master["host"].as(String), master["port"].as(Int32))
    Messenger.handshake with: master

    # now get all peers master knows about
    response = master.get "/peers"
    peers = Array(Messenger::Struct::Peer).from_json(response.body)
    # remove this node
    peers = peers.reject! { |p| p.handshake.port == Node.settings.port }
    Messenger::Repo.known_peers.concat(peers)

    # now establish connection to peers if free slots are available
    peers.sample(Messenger.connections_free).each do |peer|
      sleep 2
      idents = Messenger::Repo.peers.map { |_peer| _peer.handshake.ident }
      unless idents.includes?(peer.handshake.ident) || Node.settings.ident == peer.handshake.ident
        client = HTTP::Client.new(peer.ip_addr, peer.handshake.port)
        response = Messenger.handshake with: client

        case response.status_code
        when 200
          Messenger::Repo.peers << peer
        end
        client.close
      end
    end

    master.close
  end

  def broadcast(to endpoint : String, body : String) : Void
    Messenger::Repo.peers.each do |peer|
      client = HTTP::Client.new(peer.ip_addr, peer.handshake.port)
      begin
        client.post(
          endpoint,
          headers: HTTP::Headers{
            "Content-Type" => "application/json",
            "X-Node-Id"    => Node.settings.port.to_s,
          },
          body: body
        )
      rescue
        pp "Peer #{peer.handshake.port} is not responding"
      end
      client.close
    end
  end

  def connections_free : Int32
    free = Node.settings.max_connections - Messenger::Repo.peers.size
    return 0 if free < 0
    free
  end
end
