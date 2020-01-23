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
          amount: 100_i64
        )
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
          amount: 32_i64
        )
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
          amount: 67_i64
        )
        ],
        miner: miner
      )
    end

    before do
      Ledger::Repo.blocks[b0.hash] = b0
      Ledger::Repo.blocks[b1.hash] = b1
      Ledger::Repo.blocks[b2.hash] = b2
    end

    it "should calculate the account balance" do
      balance = Ledger::Util.balance for: myself, until: b2.hash

      balance.must_equal(1_i64)
    end
  end
end
