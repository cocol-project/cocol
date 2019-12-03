require "./deps"

class Cocol::App
  def run_api(port : Int32)
    before_all do |env|
      env.response.content_type = "application/json"
      env.response.headers["Allow"] = "HEAD,GET,PUT,POST,DELETE,OPTIONS"
      env.response.headers["Access-Control-Allow-Origin"] = "*"
      env.response.headers["Access-Control-Allow-Headers"] =
        "X-Requested-With, X-HTTP-Method-Override, Content-Type, Cache-Control, Accept"
    end

    logging false
    Kemal.run(port: port, args: nil)
  end

  # if mining
  def self.block_mining_loop
    args = CLI::Argument.parse(ARGV)
    if args.miner?
      threshold = 2
      loop do
        sleep 1

        pending_transactions_count = (
          pending_transactions = Ledger::Mempool.pending.values
        ).size

        if pending_transactions_count >= threshold
          Cocol.logger.info "[Node: #{Node.settings.port}] Mining triggered"
          mining_transactions = pending_transactions
          Ledger::Mempool.remove(mining_transactions)
          Ledger::Pow.mine(mining_transactions)
        end
      end
    end
  end

  # if staking
  # def self.block_creation_loop
  #   args = CLI::Argument.parse(ARGV)
  #   if args.miner?
  #     threshold = 2
  #     # broadcast I'm a miner
  #     loop do
  #       sleep 1

  #       pending_transactions_count = (
  #         pending_transactions = Ledger::Mempool.pending.values
  #       ).size
  #       my_turn = PoS.naive_random_selection(
  #         seed: Ledger::Repo.active_block.hash,
  #         node_id: Node.settings.ident
  #       )

  #       if pending_transactions_count >= threshold && my_turn
  #         Cocol.logger.info "[Node: #{Node.settings.port}] Creation triggered"
  #         mining_transactions = pending_transactions
  #         Ledger::Mempool.remove(mining_transactions)
  #         Ledger.workflow_create_block(mining_transactions)
  #       end
  #     end
  #   end
  # end

  def self.start
    args = CLI::Argument.parse(ARGV)
    cocol = Cocol::App.new
    Node.settings.port = args.port.to_i32
    Node.settings.max_connections = args.max_connections.to_i32
    Node.settings.miner = args.miner?
    Node.settings.master = args.master?

    spawn Node.start

    # if args.update?
    #   spawn Ledger.update_ledger
    # end

    spawn block_mining_loop
    spawn { cocol.run_api(port: args.port.to_i32) }

    loop do
      # nothing
      sleep 0.01
    end
  end
end

Cocol::App.start
