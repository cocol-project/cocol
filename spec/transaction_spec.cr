require "spec"
require "../src/cocol/node/ledger/model/transaction.cr"

describe "Ledger::Model::Transaction" do
  context "JSON Serializable" do
    txn_json = {
      from:      "Olivia",
      to:        "Teddyshum",
      amount:    100,
      timestamp: 1449970561,
      hash:      "c9b0f2181f2783594c8c30f79ef8ff6231494ab50013ed0bb0fc2cd75408f791",
    }.to_json

    it "should initialize successfully" do
      txn = Ledger::Model::Transaction.from_json(txn_json)

      txn.from.should eq("Olivia")
      txn.to.should eq("Teddyshum")
      txn.amount.should eq(100_f32)
      txn.timestamp.should eq(1449970561_i64)
      txn.hash.should eq("c9b0f2181f2783594c8c30f79ef8ff6231494ab50013ed0bb0fc2cd75408f791")
    end
  end

  context "Construct" do
    txn = Ledger::Model::Transaction.new(
      from: "Olivia",
      to: "Teddyshum",
      amount: 100_f32
    )

    it "should generate timestamp" do
      txn.timestamp.should be_truthy
    end

    it "should generate hash" do
      txn.hash.should be_truthy
    end
  end
end
