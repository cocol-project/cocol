get "/peers" do |_env|
  Messenger::Repo.peers.map { |peer|
    {
      ip_addr: "localhost",
      handshake: {
        ident: peer.handshake.ident,
        port: peer.handshake.port
      }
    }
  }.to_json
end

post "/peers" do |env|
  peer = Messenger::Struct::Peer.new(
    Messenger::Struct::Handshake.new(
    ident: UUID.new(env.params.json["ident"].as(String)),
    port: env.params.json["port"].as(Int64).to_i32
  )
  )

  # TODO: more like if Messenger.accepts_connection?(from: peer)
  if Messenger.connections_free > 0
    Messenger::Repo.peers << peer
    spawn Event.broadcast(Event.peer(peer).to_json)
    env.response.status_code = 200
  else
    env.response.status_code = 202
  end
end

get "/known-peers" do |_env|
  Messenger::Repo.known_peers.map { |peer|
    {
      ip_addr: "localhost",
      handshake: {
        ident: peer.handshake.ident,
        port: peer.handshake.port
      }
    }
  }.to_json
end

post "/internal/handshake/:port" do |env|
  target_port = env.params.url["port"].to_i32
  client = HTTP::Client.new("localhost", target_port)
  Messenger.handshake(client)
  client.close
end
