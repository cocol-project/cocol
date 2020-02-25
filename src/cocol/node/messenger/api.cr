get "/peers" do |_env|
  Messenger::Repo.peers.to_json
end

post "/peers" do |env|
  halt(
    env,
    status_code: 429,
    response: "Too Many Requests"
  ) if Messenger.free_slots <= 0

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

  spawn Event.broadcast(Event.peer(new_peer).to_json)
  Messenger::Repo.peers << new_peer

  new_peer.ident.to_s
end

get "/known-peers" do |_env|
  Messenger::Repo.known_peers.to_json
end

post "/internal/handshake/:host/:port" do |env|
  target_host = env.params.url["host"]
  target_port = env.params.url["port"].to_u32

  peer = Messenger::Struct::Peer.new(port: target_port, host: target_host)
  Messenger::Action::Handshake.call(peer)
end
