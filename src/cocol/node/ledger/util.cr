module Ledger
  module Util
    extend self

    def probfin_tip_hash : String
      current = ProbFin::Chain.dag[Ledger::Repo.ledger.last]
      DAG.tip_of_longest_branch(from: current).vertex.name
    end

    def balance(for address : String) : Int64
      tip = probfin_tip_hash

      balance for: address, until: tip
    end

    def balance(for address : String, until block_hash : String) : Int64
      balance(for: address,
              until: block_hash,
              result: 0_i64)
    end

    protected def balance(
      for address : String,
      until block_hash : String,
      result : Int64
    ) : Int64
      block = Ledger::Repo.blocks[block_hash]
      result = balance(for: address,
              until: block.previous_hash,
              result: result) if block.previous_hash != Ledger::GENESIS_CREATOR

      block.transactions.each do |txn|
        result = result + txn.amount if txn.to == address
        result = result - txn.amount if txn.from == address
      end

      result
    end
  end
end
