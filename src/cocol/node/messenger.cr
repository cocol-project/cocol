require "./messenger/**"

module Messenger
  extend self

  class PeerURI
    def initialize(from peer : Messenger::Struct::Peer) : URI
      URI.new(
        scheme: "http",
        host: peer.ip_addr,
        port: peer.port
      )
    end
  end

  module Action
    module Base
      extend self

      def broadcast(to endpoint : String, payload : String) : Void
        Messenger::Repo.peers.each do |peer|
          peer_uri = Messenger::PeerURI.new(peer)
          post(to: peer_uri, body: payload)
        end
      end

      def post(
        to uri : URI,
        body : String
      ) : HTTP::Client::Response
        client = HTTP::Client.new(uri)
        begin
          client.post(
            headers: HTTP::Headers{
              "Content-Type" => "application/json",
              "X-Node-Id"    => Node.settings.ident.to_s,
            },
            body: body
          )
        rescue
          Cocol.logger.warn "Peer is not responding at POST-#{uri}"
        end
        client.close
      end

      def get(from uri : URI) : HTTP::Client::Response
        client = HTTP::Client.new(uri)
        begin
          client.get(
            headers: HTTP::Headers{
              "Content-Type" => "application/json",
              "X-Node-Id"    => Node.settings.ident.to_s,
            }
          )
        rescue
          Cocol.logger.warn "Peer is not responding at GET-#{uri}"
        end
        client.close
      end
    end

    module Handshake
      include Base
      extend self

      PATH = "/peers"

      def call(peer : Messenger::Struct::Peer) : HTTP::Client::Reponse
        payload = Messenger::Struct::Peer.new(Node.settings.peer_info)
        uri = Messenger::PeerUri.new(from: peer)
        uri.path = PATH
        post(to: uri, body: payload.to_json)
      end
    end

    module GetPeers
      include Base
      extend self

      PATH = "/peers"

      def call(peer : Messenger::Struct::Peer) : Array(Messenger::Struct::Peer)
        uri = Messenger::PeerURI.new from: peer
        uri.path = PATH
        response.body = get(from: uri)
        Array(Messenger::Struct::Peer).from_json(response.body)
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
    peers.sample(Messenger.free_slots) do |peer|
      sleep 1
      next if Node.settings.ident == peer.ident
      next if Messenger::Action::Handshake.call(peer).status_code != 200

      Messenger::Repo.peers.add(peer)
    end
  end


  def free_slots : Int32
    free = Node.settings.max_connections - Messenger::Repo.peers.size
    return 0 if free < 0
    free
  end
end
