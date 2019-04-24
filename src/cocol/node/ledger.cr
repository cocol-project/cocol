require "./ledger/model/block"
require "./ledger/model/transaction"

require "./ledger/repo"

require "./event.cr"

require "./settings.cr"
require "./messenger.cr"

require "./ledger/api.cr"

module Node
  module Ledger
    extend self

    alias TxnHash = String

    def workflow_genesis_block : Void
      Node::Ledger::Repo.ledger.clear
      Node::Ledger::Repo.orphans.clear
      Node::Ledger::Repo.candidates.clear
      Node::Ledger::Repo.blocks.clear
      Node::Ledger::Repo.established_height = 0

      genesis = Node::Ledger::Model::Block.genesis

      Node::Ledger::Repo.blocks[genesis.hash] = genesis
      Node::Ledger::Repo.ledger << genesis.hash
    end

    def workflow_mine(transactions : Array(Node::Ledger::Model::Transaction), difficulty_bits : Int32 = 1) : Void
      active_block = Node::Ledger::Repo.active_block
      raise "No active block" unless active_block

      if Node::Ledger::Repo.candidates.size > 0
        previous_hash = first_candidate()
        # previous_hash = Node::Ledger::Repo.candidates.first
        height = Node::Ledger::Repo.blocks[previous_hash].height + 1
      else
        previous_hash = active_block.hash
        height = active_block.height + 1
      end

      new_block = Node::Ledger::Model::Block.new(
        height: height,
        transactions: transactions,
        previous_hash: previous_hash,
        difficulty_bits: difficulty_bits
      )

      if Node::Ledger::Repo.save_block(new_block)
        pp "[#{Time.now}] [Node: #{Node.settings.port}] Mined: #{new_block.hash}"
        Node::Ledger::Repo.delete_transactions(transactions)
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

      Node::Ledger::Repo.ledger.concat(ledger)
    end

    def first_candidate : String
      tc = Node::Ledger::Repo.candidates.map { |c| [c, Node::Ledger::Repo.blocks[c].timestamp] }
      tcs = tc.sort { |a,b| a[1].as(Int64) <=> b[1].as(Int64) }

      return tcs.last[0].as(String)
    end

    def workflow_assign_block(block : Node::Ledger::Model::Block) : Void
      if Node::Ledger::Repo.ledger.last == block.previous_hash
        Node::Ledger::Repo.candidates << block.hash
      elsif block.previous_hash == first_candidate()
        # establish parent
        Node::Ledger::Repo.establish(block.previous_hash, Node::Ledger::Repo.blocks[block.previous_hash].height)
        # clear candidates
        Node::Ledger::Repo.candidates.clear
        # check for orphan
        if orphan = Node::Ledger::Repo.orphans[block.hash]?
          # establish current
          Node::Ledger::Repo.establish(block.hash, block.height)

          # vote orphan for candidate
          Node::Ledger::Repo.candidates << orphan
          # remove from orphans
          Node::Ledger::Repo.orphans.delete(block.hash)
        else
          # vote current for candidate
          Node::Ledger::Repo.candidates << block.hash
        end
      elsif !Node::Ledger::Repo.ledger.includes?(block.previous_hash)
        if !Node::Ledger::Repo.blocks[block.previous_hash]?
          # it's an orphan
          Node::Ledger::Repo.orphans[block.previous_hash] = block.hash
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
          block = Node::Ledger::Model::Block.from_json(json_block.to_json)
          Node::Ledger::Repo.blocks[block.hash] = block
          Node::Ledger::Repo.establish(block.hash, block.height)
        end
        Event.broadcast(Event.update("onInitialUpdate").to_json)
      else
        sleep 1
        update_ledger
      end
    end

  end
end
