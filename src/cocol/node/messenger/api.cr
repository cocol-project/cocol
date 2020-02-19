get "/peers" do |_env|
  Messenger::Repo.peers.to_json
end

post "/peers" do |env|
  halt(
    env,
    status_code: 429,
    response: "Too Many Requests"
  ) if Messenger.connections_free <= 0

  begin
    new_peer = Messenger::Struct::Peer.from_json(
        env.request.body.not_nil!)
  rescue
    halt(
      env,
      status_code: 400,
      response: "Bad Request"
    )
  end

  spawn Event.broadcast(Event.peer(peer).to_json)
  Messenger::Repo.peers << new_peer

  new_peer.ident.to_s
end

get "/known-peers" do |_env|
  Messenger::Repo.known_peers.to_json
end

post "/internal/handshake/:ip_addr/:port" do |env|
  target_ip_addr = env.params.url["ip_addr"]
  target_port = env.params.url["port"].to_i32
  client = HTTP::Client.new(target_ip_addr, target_port)
  Messenger.handshake(client)
  client.close
end
