module Node
  extend self

  # should be e2e tested
  def start(args : CLI::Argument, cocol : Cocol::App, &block)
    Node.settings.port = args.port.to_i32
    Node.settings.max_connections = args.max_connections.to_i32
    Node.settings.miner = args.miner?
    Node.settings.master = args.master?

    Cocol::Pos::ValidatorPool.add(id: "4001", timestamp: Time.utc.to_unix)
    Cocol::Pos::ValidatorPool.add(id: "4002", timestamp: Time.utc.to_unix + 1)
    Cocol::Pos::ValidatorPool.add(id: "4003", timestamp: Time.utc.to_unix + 2)
    Cocol::Pos::ValidatorPool.add(id: "4004", timestamp: Time.utc.to_unix + 3)

    Ledger::Pos.genesis

    spawn { cocol.run_api(port: args.port.to_i32) }

    if !Node.settings.master
      Messenger.establish_network_position
    end

    yield

    loop do
      # nothing
      sleep 0.01
    end
  end
end
