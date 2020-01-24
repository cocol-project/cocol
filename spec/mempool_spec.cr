require "./spec_helper"

describe "Ledger::Mempool" do
  let(:txn) do
    Ledger::Model::Transaction.new("VW", "Merkel", 3_000_u64)
  end

  describe "Managing pending transactions" do
    before do
      Ledger::Mempool.pending.clear
    end

    it "should return false when trying to remove unknown txn" do
      Ledger::Mempool.remove(txn.hash).must_equal(false)
    end

    it "should return true when trying to add unknown txn" do
      Ledger::Mempool.add(txn).must_equal(true)
    end

    it "should return false when trying to add known txn" do
      Ledger::Mempool.add(txn)
      Ledger::Mempool.add(txn).must_equal(false)
    end

    it "should return true when trying to remove known txn" do
      Ledger::Mempool.add(txn)
      Ledger::Mempool.remove(txn.hash).must_equal(true)
    end
  end
end
