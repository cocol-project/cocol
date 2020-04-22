# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at # http://mozilla.org/MPL/2.0/

require "./ledger/util"
require "./ledger/block"
require "./ledger/action"
require "./ledger/mempool"
require "./ledger/repo"
require "./ledger/api"
require "./event"
require "./messenger"

module Ledger
  GENESIS_CREATOR = "Olivia"

  module Inventory
    extend self
    include Ledger::Block

    def call(best_hash : BlockHash) : Array(BlockHash)
      peer_best_block = Ledger::Repo.blocks[best_hash]?
      return Array(BlockHash).new if peer_best_block.nil?

      Ledger::Repo.blocks.map do |k, v|
        k if v.height > peer_best_block.height
      end.compact
    end
  end

  module Sync
    extend self
    include Ledger::Block

    def call
      Cocol.logger.info { "--- START SYNC" }
      loop do
        sleep 0.5
        next if Messenger::Repo.peers.size == 0

        peer = Messenger::Repo.peers.first
        best_hash = Ledger::Util.probfin_tip_hash
        peer_inventory = Messenger::Action::Inventory.call(
          peer: peer,
          best_hash: best_hash
        )
        break if peer_inventory.size == 0
        my_inventory = Ledger::Inventory.call(best_hash)
        inventory = peer_inventory - my_inventory

        inventory.each do |bh|
          next if Ledger::Repo.blocks[bh]?
          block = Messenger::Action::GetBlock.call(block_hash: bh, peer: peer)
          next if !Ledger::Pow.valid?(block: block)

          Ledger::Pow.submit(block, broadcast: false)
        end
      end
      Cocol.logger.info { "--- SYNC FINISHED" }
    end
  end

  module Pow
    extend self
    include Ledger::Block
    include Ledger::Action

    RETARGET_TIMESPAN = 60_f64 # In seconds (I think *g*)

    def genesis : Nil
      Ledger::Repo.ledger.clear
      Ledger::Repo.blocks.clear
      Ledger::Repo.block_at_height.clear

      genesis = Ledger::Block::Pow.new(
        hash: "000003816de5a8feb130232390a28ac3566d483bde194ae6b503fec96993dffc",
        timestamp: 1582643058_i64,
        height: 0_u64,
        nonce: 2058209_u64,
        nbits: Ledger::Block::Pow::MIN_NBITS,
        previous_hash: "a78a4203908a94d91b1a8f6aa65f4d1176d68ba67ced10a32cfb661f40c58b88",
        transactions: Array(Ledger::Action::Transaction).new,
        coinbase: Block::Coinbase.new(miner: "Olivia", reward: 1_u64)
      )

      Ledger::Repo.blocks[genesis.hash] = genesis
      Ledger::Repo.finalize(block: genesis.hash)
      ProbFin.push(block: genesis.hash, parent: genesis.previous_hash)
    end

    def mine(transactions : Array(Ledger::Action::Transaction)) : Ledger::Block::Pow
      tip_hash = Ledger::Util.probfin_tip_hash
      height = Ledger::Repo.blocks[tip_hash].height + 1

      if height % 20 == 0 # retargeting
        difficulty = CCL::Pow::Utils.retarget(
          **timespan_from_tip(hash: tip_hash),
          wanted_timespan: RETARGET_TIMESPAN,
          current_target: CCL::Pow::Utils.calculate_target(
            from: Ledger::Repo.blocks[tip_hash].as(Block::Pow).nbits
          ),
          min_target: Ledger::Block::Pow.min_target
        )
        Cocol.logger.info { "New target: #{difficulty}" }
      else # last blocks difficulty
        difficulty = Ledger::Repo.blocks[tip_hash].as(Block::Pow).nbits
      end

      new_block = Ledger::Block::Pow.new(
        height: height,
        transactions: transactions,
        previous_hash: tip_hash,
        nbits: difficulty,
        coinbase: Block::Coinbase.new(miner: Node.settings.miner_address.as(String))
      )

      Cocol.logger.info { "--- MINED Height: #{new_block.height} NBits: #{new_block.nbits} Block: #{new_block.hash}" }
      submit(new_block)

      new_block
    end

    def valid?(block : Ledger::Block::Abstract) : Bool
      sha = OpenSSL::Digest.new("SHA256")
      sha.update("#{block.nonce}#{block.hash_seed}")

      block.hash == sha.hexdigest
    end

    def submit(block : Ledger::Block::Pow, broadcast = true)
      return if !Ledger::Repo.save block

      Cocol.logger.info { "Height: #{block.height} NBits: #{block.nbits} Block: #{block.hash}" }

      Ledger::Mempool.remove(block.transactions)
      ProbFin.push(block: block.hash, parent: block.previous_hash)
      result = ProbFin.finalize(
        from: Ledger::Repo.ledger.last
      )
      if result.class == BlockHash
        Ledger::Repo.finalize(result.as(BlockHash))
      end

      if broadcast
        spawn { Messenger::Action::Base.broadcast to: "/blocks/pow", body: block.to_json }

        spawn Event.broadcast(Event.update("onInitialUpdate").to_json)
        spawn Event.broadcast(Event.block(block).to_json)
      end
    end

    private def timespan_from_tip(hash : String) : NamedTuple
      last_block = Ledger::Repo.blocks[hash].as(Block::Pow)
      way_back_block = first_block(hash, 19)

      {
        start_time: way_back_block.timestamp.to_f64,
        end_time:   last_block.timestamp.to_f64,
      }
    end

    private def first_block(hash : String, count : UInt8)
      return Ledger::Repo.blocks[hash].as(Block::Pow) if count <= 0_u8
      first_block(Ledger::Repo.blocks[hash].previous_hash, count - 1_u8)
    end

    private def genesis_transactions : Array(Ledger::Action::Transaction)
      txns = [] of Ledger::Action::Transaction

      txns << Ledger::Action::Transaction.new(
        from: "Olivia",
        to: "0x904F4094aeaadce2d46512BaeEc920977e90e7c9",
        amount: 100000_u64
      )
    end
  end

  module Pos
    extend self
    include Ledger::Block

    def genesis : Nil
      Ledger::Repo.ledger.clear
      Ledger::Repo.blocks.clear
      Ledger::Repo.block_at_height.clear

      genesis = Ledger::Block::Pos.new(
        hash: "00000f33293fc3092f436fec6480ba8460589087f2118c1c2d4a60f35372f297",
        timestamp: 1449966000_i64,
        height: 0_u64,
        transactions: Array(Ledger::Action::Transaction).new,
        stakes: Array(Ledger::Action::Stake).new,
        previous_hash: Ledger::GENESIS_CREATOR,
        coinbase: Coinbase.new("3000")
      )
      # Cocol::Pos::ValidatorPool.add(id: "4001", timestamp: Time.utc.to_unix)
      # Cocol::Pos::ValidatorPool.add(id: "4002", timestamp: Time.utc.to_unix + 1)
      # Cocol::Pos::ValidatorPool.add(id: "4003", timestamp: Time.utc.to_unix + 2)
      # Cocol::Pos::ValidatorPool.add(id: "4004", timestamp: Time.utc.to_unix + 3)

      Ledger::Repo.blocks[genesis.hash] = genesis
      Ledger::Repo.finalize(block: genesis.hash)
      ProbFin.push(block: genesis.hash, parent: genesis.previous_hash)

      new_block_if_leader
    end

    def mine(
      transactions : Array(Ledger::Action::Transaction),
      stakes : Array(Ledger::Action::Stake)
    ) : Nil
      tip_hash = Ledger::Util.probfin_tip_hash
      height = Ledger::Repo.blocks[tip_hash].height + 1

      stakes << Ledger::Action::Stake.new(
        staker: Node.settings.miner_address.as(String),
        amount: 33_u64,
      )

      new_block = Ledger::Block::Pos.new(
        height: height,
        transactions: transactions,
        stakes: stakes,
        previous_hash: tip_hash,
        coinbase: Coinbase.new(Node.settings.miner_address.as(String)),
      )

      if Ledger::Repo.save(block: new_block)
        Cocol.logger.info { "Height: #{new_block.height} Mined: #{new_block.hash[-7..-1]}" }
        spawn Event.broadcast(Event.block(new_block).to_json)
        on_save new_block
      end
    end

    def valid?(block : Ledger::Block::Pos) : Bool
      block.hash == block.calc_hash
    end

    def validate(block : Ledger::Block::Pos) : Nil
      if Ledger::Repo.save(block: block)
        Cocol.logger.debug { "BLOCK Height: #{block.height} | Saved: #{block.hash[-7..-1]}" }
        on_save block
      end
    end

    def on_save(block)
      Ledger::Mempool.remove block.transactions
      ProbFin.push(block: block.hash, parent: block.previous_hash)
      spawn { Messenger::Action::Base.broadcast to: "/blocks/pos", body: block.to_json }
      spawn Event.broadcast(Event.update("onInitialUpdate").to_json)
      remove_validator block.coinbase.miner
      add_stakers block.stakes
      new_block_if_leader
    end

    def add_stakers(stakes : Array(Ledger::Action::Stake)) : Nil
      stakes.each do |s|
        Cocol.logger.debug { "VALIDATOR ADDED: #{s.staker}" }
        CCL::Pos::ValidatorPool.add(id: s.staker, timestamp: s.timestamp)
      end
    end

    def remove_validator(id : String)
      Cocol.logger.debug { "VALIDATOR REMOVED: #{id}" }
      CCL::Pos::ValidatorPool.remove id
      Cocol.logger.debug { "VALIDATORS: #{CCL::Pos::ValidatorPool.validators}" }
    end

    def new_block_if_leader
      if Node.settings.miner
        my_turn = CCL::Pos.naive_leader?(
          seed: Ledger::Util.probfin_tip_hash,
          validator_id: Node.settings.miner_address.as(String)
        )
        Cocol.logger.debug { "MY_TURN: #{my_turn}" }
        spawn block_creation_loop if my_turn
      end
    end

    def block_creation_loop
      Cocol.logger.info { "Creation loop triggered" }
      threshold = 2
      loop do
        sleep 0.333
        if (pending_transactions = Ledger::Mempool.pending.values).size >= threshold
          mining_transactions = pending_transactions
          Ledger::Mempool.remove(mining_transactions)
          Ledger::Pos.mine(mining_transactions, Array(Ledger::Action::Stake).new)

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
  #       block = Ledger::Action::Block.from_json(json_block.to_json)
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
