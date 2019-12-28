require "./spec_helper"

describe Ledger::Pow do
  describe "Genesis" do
    it "created the genesis block" do
      Ledger::Pow.genesis
      Ledger::Repo.blocks[Ledger::Repo.block_at_height[0_u64]].previous_hash.must_equal("Olivia")
    end
  end

  describe "Mine" do
    it "mines a block" do
      transactions = Array(Ledger::Model::Transaction).new
      txn = Ledger::Model::Transaction.new(
        from: "me",
        to: "you",
        amount: 1_i64
      )
      transactions << txn

      block = Ledger::Pow.mine(transactions)

      block.transactions.must_equal(transactions)
      block.nonce.wont_be_nil
      block.nbits.wont_be_nil
      block.timestamp.wont_be_nil
    end
  end
end
