require "./ledger/**"
require "./event"
require "./messenger"

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
        Cocol.logger.info "Height: #{new_block.height} NBits: #{new_block.nbits} Mined: #{new_block.hash}"
        Ledger::Mempool.remove(transactions)
        ProbFin.push(block: new_block.hash, parent: new_block.previous_hash)

        spawn { Messenger.broadcast to: "/blocks/pow", body: new_block.to_json }

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
        hash: "00000f33293fc3092f436fec6480ba8460589087f2118c1c2d4a60f35372f297",
        timestamp: 1449966000_i64,
        height: 0_u64,
        transactions: Array(Ledger::Model::Transaction).new,
        stakes: Array(Ledger::Model::Stake).new,
        previous_hash: "Olivia",
        miner: "3000"
      )

      Ledger::Repo.blocks[genesis.hash] = genesis
      Ledger::Repo.finalize(block: genesis.hash)
      ProbFin.push(block: genesis.hash, parent: genesis.previous_hash)

      new_block_if_leader
    end

    def mine(
      transactions : Array(Ledger::Model::Transaction),
      stakes : Array(Ledger::Model::Stake)
    ) : Nil
      previous_hash = Ledger::Helper.probfin_previous_hash
      height = Ledger::Repo.blocks[previous_hash].height + 1

      stakes << Ledger::Model::Stake.new(
        staker: Node.settings.port.to_s,
        amount: 33_i64,
      )

      new_block = Ledger::Model::Block::Pos.new(
        height: height,
        transactions: transactions,
        stakes: stakes,
        previous_hash: previous_hash,
        miner: Node.settings.port.to_s,
      )

      if Ledger::Repo.save(block: new_block)
        Cocol.logger.info "Height: #{new_block.height} Mined: #{new_block.hash[-7..-1]}"
        spawn Event.broadcast(Event.block(new_block).to_json)
        on_save new_block
      end
    end

    def validate(block : Ledger::Model::Block::Pos) : Nil
      if Ledger::Repo.save(block: block)
        Cocol.logger.debug "BLOCK Height: #{block.height} | Saved: #{block.hash[-7..-1]}"
        on_save block
      end
    end

    def on_save(block)
      Ledger::Mempool.remove block.transactions
      ProbFin.push(block: block.hash, parent: block.previous_hash)
      spawn { Messenger.broadcast to: "/blocks/pos", body: block.to_json }
      spawn Event.broadcast(Event.update("onInitialUpdate").to_json)
      remove_validator block.miner
      add_stakers block.stakes
      new_block_if_leader
    end

    def add_stakers(stakes : Array(Ledger::Model::Stake)) : Nil
      stakes.each do |s|
        Cocol.logger.debug "VALIDATOR ADDED: #{s.staker}"
        CCL::Pos::ValidatorPool.add(id: s.staker, timestamp: s.timestamp)
      end
    end

    def remove_validator(id : String)
      Cocol.logger.debug "VALIDATOR REMOVED: #{id}"
      CCL::Pos::ValidatorPool.remove id
      Cocol.logger.debug "VALIDATORS: #{CCL::Pos::ValidatorPool.validators}"
    end

    def new_block_if_leader
      if Node.settings.miner
        my_turn = CCL::Pos.naive_leader?(
          seed: Ledger::Helper.probfin_previous_hash,
          validator_id: Node.settings.port.to_s
        )
        Cocol.logger.debug "MY_TURN: #{my_turn}"
        spawn block_creation_loop if my_turn
      end
    end

    def block_creation_loop
      Cocol.logger.info "Creation loop triggered"
      threshold = 2
      loop do
        sleep 0.333
        if (pending_transactions = Ledger::Mempool.pending.values).size >= threshold
          mining_transactions = pending_transactions
          Ledger::Mempool.remove(mining_transactions)
          Ledger::Pos.mine(mining_transactions, Array(Ledger::Model::Stake).new)

          break
        end
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
