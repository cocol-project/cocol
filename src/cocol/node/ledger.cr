require "../logger.cr"
require "./ledger/model/block"
require "./ledger/model/transaction"

require "./ledger/repo"
require "./ledger/mempool"

require "./event.cr"

require "./settings.cr"
require "./messenger.cr"

require "./ledger/api.cr"

require "probfin"

module Ledger
  module Helper
    extend self

    def probfin_previous_hash : String
      current = ProbFin::Chain.dag[Ledger::Repo.ledger.last]
      DAG.tip_of_longest_branch(from: current).vertex.name
    end
  end

  module Pow
    extend self

    RETARGET_TIMESPAN = 60_f64 # In seconds (I think *g*)

    def genesis : Nil
      Ledger::Repo.ledger.clear
      Ledger::Repo.blocks.clear
      Ledger::Repo.block_at_height.clear

      genesis = Ledger::Model::Block::Pow.new(
        hash: "00000f33293fc3092f436fec6480ba8460589087f2118c1c2d4a60f35372f297",
        timestamp: 1449966000_i64,
        height: 0_u64,
        nonce: 2174333_u64,
        nbits: Ledger::Model::Block::Pow::MIN_NBITS,
        previous_hash: "Olivia",
        transactions: Array(Ledger::Model::Transaction).new
      )

      Ledger::Repo.blocks[genesis.hash] = genesis
      Ledger::Repo.finalize(block: genesis.hash)
      ProbFin.push(block: genesis.hash, parent: genesis.previous_hash)
    end

    def mine(transactions : Array(Ledger::Model::Transaction)) : Ledger::Model::Block::Pow
      previous_hash = Ledger::Helper.probfin_previous_hash
      height = Ledger::Repo.blocks[previous_hash].height + 1

      if height % 20 == 0 # retargeting
        Cocol.logger.info "Retargeting Now"
        difficulty = BTCPoW::Utils.retarget(
          **timespan_from_height(height: height),
          wanted_timespan: RETARGET_TIMESPAN,
          current_target: BTCPoW::Utils.calculate_target(
            from: Ledger::Repo.blocks[previous_hash].as(Model::Block::Pow).nbits
          )
        )
      else # last blocks difficulty
        difficulty = Ledger::Repo.blocks[previous_hash].as(Model::Block::Pow).nbits
      end

      new_block = Ledger::Model::Block::Pow.new(
        height: height,
        transactions: transactions,
        previous_hash: previous_hash,
        nbits: difficulty
      )

      if Ledger::Repo.save(block: new_block)
        Cocol.logger.info "[Node: #{Node.settings.port}] Height: #{new_block.height} NBits: #{new_block.nbits} Mined: #{new_block.hash}"
        Ledger::Mempool.remove(transactions)
        ProbFin.push(block: new_block.hash, parent: new_block.previous_hash)

        spawn { Messenger.broadcast to: "/blocks", body: new_block.to_json }

        spawn Event.broadcast(Event.update("onInitialUpdate").to_json)
        spawn Event.broadcast(Event.block(new_block).to_json)
      end

      new_block
    end

    private def timespan_from_height(height : UInt64) : NamedTuple
      first_block = Ledger::Repo.blocks[Ledger::Repo.block_at_height[height - 20]].as(Model::Block::Pow)
      last_block = Ledger::Repo.blocks[Ledger::Repo.block_at_height[height - 1]].as(Model::Block::Pow)

      {
        start_time: first_block.timestamp.to_f64,
        end_time:   last_block.timestamp.to_f64,
      }
    end
  end

  module Pos
    extend self

    def genesis : Nil
      Ledger::Repo.ledger.clear
      Ledger::Repo.blocks.clear
      Ledger::Repo.block_at_height.clear

      genesis = Ledger::Model::Block::Pos.new(
        height: 0_u64,
        transactions: Array(Ledger::Model::Transaction).new,
        stakes: Array(Ledger::Model::Stake).new,
        previous_hash: "Olivia"
      )

      Ledger::Repo.blocks[genesis.hash] = genesis
      Ledger::Repo.finalize(block: genesis.hash)
      ProbFin.push(block: genesis.hash, parent: genesis.previous_hash)
    end

    def mine(
      transactions : Array(Ledger::Model::Transaction),
      stakes : Array(Ledger::Model::Stake)
    ) : Nil
      previous_hash = Ledger::Helper.probfin_previous_hash
      height = Ledger::Repo.blocks[previous_hash].height + 1

      new_block = Ledger::Model::Block::Pos.new(
        height: height,
        transactions: transactions,
        stakes: stakes,
        previous_hash: previous_hash,
      )

      if Ledger::Repo.save(block: new_block)
        Cocol.logger.info "[Node: #{Node.settings.port}] Height: #{new_block.height} Mined: #{new_block.hash}"
        Ledger::Mempool.remove(transactions)
        ProbFin.push(block: new_block.hash, parent: new_block.previous_hash)

        spawn { Messenger.broadcast to: "/blocks", body: new_block.to_json }

        spawn Event.broadcast(Event.update("onInitialUpdate").to_json)
        spawn Event.broadcast(Event.block(new_block).to_json)
      end
    end
  end

  # def workflow_fetch_ledger(client : HTTP::Client) : Void
  #   response = client.get "/ledger"
  #   ledger = Array(String).from_json(response.body)

  #   # compare with my ledger

  #   Ledger::Repo.ledger.concat(ledger)
  # end

  # def update_ledger : Void
  #   # pick first peer
  #   if peer = Messenger::Repo.peers.first?
  #     client = HTTP::Client.new(peer.ip_addr, peer.handshake.port)

  #     response = client.get "/blocks"
  #     json_ledger = JSON.parse(response.body)

  #     json_ledger.as_a.each do |json_block|
  #       block = Ledger::Model::Block.from_json(json_block.to_json)
  #       Ledger::Repo.blocks[block.hash] = block
  #       Ledger::Repo.establish(block.hash, block.height)
  #     end
  #     Event.broadcast(Event.update("onInitialUpdate").to_json)
  #   else
  #     sleep 1
  #     update_ledger
  #   end
  # end
end
