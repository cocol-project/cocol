require "spec"
require "../src/cocol/node/ledger/mempool"

describe "Ledger::Mempool" do
  txn = Ledger::Model::Transaction.new("VW", "Merkel", 3_000_f32)

  context "Managing pending transactions" do
    it "should return false when trying to remove unknown txn" do
      Ledger::Mempool.remove(txn.hash).should eq(false)
    end

    it "should return true when trying to add unknown txn" do
      Ledger::Mempool.add(txn).should eq(true)
    end

    it "should return false when trying to add known txn" do
      Ledger::Mempool.add(txn).should eq(false)
    end

    it "should return true when trying to remove known txn" do
      Ledger::Mempool.remove(txn.hash).should eq(true)
    end
  end
end
