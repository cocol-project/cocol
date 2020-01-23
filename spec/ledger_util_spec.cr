require "./spec_helper"

describe "Ledger::Util" do
  describe "Balance" do
    let(:miner) { "3000" }
    let(:nobody) { "nobody" }
    let(:myself) { "myself" }

    let(:b0) do
      Ledger::Model::Block::Pos.new(
        height: 0_u64,
        previous_hash: Ledger::GENESIS_CREATOR,
        stakes: Array(Ledger::Model::Stake).new,
        transactions: [
          Ledger::Model::Transaction.new(
            from: nobody,
            to: myself,
            amount: 100_u64
          ),
        ],
        miner: miner
      )
    end
    let(:b1) do
      Ledger::Model::Block::Pos.new(
        height: 0_u64,
        previous_hash: b0.hash,
        stakes: Array(Ledger::Model::Stake).new,
        transactions: [
          Ledger::Model::Transaction.new(
            from: myself,
            to: nobody,
            amount: 32_u64
          ),
        ],
        miner: miner
      )
    end
    let(:b2) do
      Ledger::Model::Block::Pos.new(
        height: 0_u64,
        previous_hash: b1.hash,
        stakes: Array(Ledger::Model::Stake).new,
        transactions: [
          Ledger::Model::Transaction.new(
            from: myself,
            to: nobody,
            amount: 67_u64
          ),
        ],
        miner: miner
      )
    end

    let(:txn_over_limit) do
      Ledger::Model::Transaction.new(
        from: myself,
        to: nobody,
        amount: 12412512532_u64
      )
    end
    let(:txn_in_limit) do
      Ledger::Model::Transaction.new(
        from: myself,
        to: nobody,
        amount: 1_u64
      )
    end

    before do
      Ledger::Repo.blocks[b0.hash] = b0
      Ledger::Repo.blocks[b1.hash] = b1
      Ledger::Repo.blocks[b2.hash] = b2
    end

    it "should calculate the account balance" do
      balance = Ledger::Util.balance for: myself, until: b2.hash

      balance.must_equal(1_u64)
    end

    it "should calculate 0 for unknown address" do
      balance = Ledger::Util.balance for: "unknown", until: b2.hash

      balance.must_equal(0_u64)
    end

    it "should return false for over-limit transaction" do
      is_valid = Ledger::Util.valid? transaction: txn_over_limit, at: b2.hash

      is_valid.must_equal(false)
    end

    it "should return true for in-limit transaction" do
      is_valid = Ledger::Util.valid? transaction: txn_in_limit, at: b2.hash

      is_valid.must_equal(true)
    end
  end
end
