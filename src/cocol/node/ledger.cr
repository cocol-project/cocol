require "./ledger/model/block"
require "./ledger/model/transaction"

require "./ledger/repo"
require "./ledger/mempool"

require "./event.cr"

require "./settings.cr"
require "./messenger.cr"

require "./ledger/api.cr"

require "btcpow"

module Ledger
  extend self

  alias TxnHash = String

  def workflow_genesis_block : Void
    Ledger::Repo.ledger.clear
    Ledger::Repo.orphans.clear
    Ledger::Repo.candidates.clear
    Ledger::Repo.blocks.clear
    Ledger::Repo.established_height = 0

    genesis = Ledger::Model::Block.genesis

    Ledger::Repo.blocks[genesis.hash] = genesis
    Ledger::Repo.height[0] = genesis.hash
    Ledger::Repo.ledger << genesis.hash
  end

  def workflow_mine(transactions : Array(Ledger::Model::Transaction)) : Void
    active_block = Ledger::Repo.active_block
    raise "No active block" unless active_block

    if Ledger::Repo.candidates.size > 0
      previous_hash = first_candidate()
      height = Ledger::Repo.blocks[previous_hash].height + 1
    else
      previous_hash = active_block.hash
      height = active_block.height + 1
    end

    if height % 20 == 0
      Cocol.logger.info "Retargeting Now"

      first_block = Ledger::Repo.blocks[Ledger::Repo.height[height - 20]]
      last_block = Ledger::Repo.blocks[Ledger::Repo.height[height - 1]]
      difficulty = BTCPoW::Utils.retarget(
        start_time: first_block.timestamp.to_f64,
        end_time: last_block.timestamp.to_f64,
        wanted_timespan: 60_f64,
        current_target: BTCPoW::Utils.calculate_target(from: last_block.nbits)
      )
    else # last blocks difficulty
      difficulty = Ledger::Repo.blocks[previous_hash].nbits
    end

    new_block = Ledger::Model::Block.new(
      height: height,
      transactions: transactions,
      previous_hash: previous_hash,
      difficulty: difficulty
    )

    if Ledger::Repo.save_block(new_block)
      Cocol.logger.info "[Node: #{Node.settings.port}] Height: #{new_block.height} NBits: #{new_block.nbits} Mined: #{new_block.hash}"
      # Ledger::Repo.delete_transactions(transactions)
      workflow_assign_block(new_block)

      spawn { Messenger.broadcast to: "/blocks", body: new_block.to_json }

      spawn Event.broadcast(Event.update("onInitialUpdate").to_json)
      spawn Event.broadcast(Event.block(new_block).to_json)
    end
  end

  def workflow_fetch_ledger(client : HTTP::Client) : Void
    response = client.get "/ledger"
    ledger = Array(String).from_json(response.body)

    # compare with my ledger

    Ledger::Repo.ledger.concat(ledger)
  end

  def first_candidate : String
    tc = Ledger::Repo.candidates.map { |c| [c, Ledger::Repo.blocks[c].timestamp] }
    tcs = tc.sort { |a, b| a[1].as(Int64) <=> b[1].as(Int64) }

    return tcs.last[0].as(String)
  end

  def workflow_assign_block(block : Ledger::Model::Block) : Void
    if Ledger::Repo.ledger.last == block.previous_hash
      Ledger::Repo.candidates << block.hash
    elsif block.previous_hash == first_candidate()
      # establish parent
      Ledger::Repo.establish(block.previous_hash, Ledger::Repo.blocks[block.previous_hash].height)
      # clear candidates
      Ledger::Repo.candidates.clear
      # check for orphan
      if orphan = Ledger::Repo.orphans[block.hash]?
        # establish current
        Ledger::Repo.establish(block.hash, block.height)

        # vote orphan for candidate
        Ledger::Repo.candidates << orphan
        # remove from orphans
        Ledger::Repo.orphans.delete(block.hash)
      else
        # vote current for candidate
        Ledger::Repo.candidates << block.hash
      end
    elsif !Ledger::Repo.ledger.includes?(block.previous_hash)
      if !Ledger::Repo.blocks[block.previous_hash]?
        # it's an orphan
        Ledger::Repo.orphans[block.previous_hash] = block.hash
      end
    end
  end

  def update_ledger : Void
    # pick first peer
    if peer = Messenger::Repo.peers.first?
      client = HTTP::Client.new(peer.ip_addr, peer.handshake.port)

      response = client.get "/blocks"
      json_ledger = JSON.parse(response.body)

      json_ledger.as_a.each do |json_block|
        block = Ledger::Model::Block.from_json(json_block.to_json)
        Ledger::Repo.blocks[block.hash] = block
        Ledger::Repo.establish(block.hash, block.height)
      end
      Event.broadcast(Event.update("onInitialUpdate").to_json)
    else
      sleep 1
      update_ledger
    end
  end
end
