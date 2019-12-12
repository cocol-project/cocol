require "./spec_helper"

describe "Ledger::Model::Transaction" do
  let(:hash) { "c9b0f2181f2783594c8c30f79ef8ff6231494ab50013ed0bb0fc2cd75408f791" }
  let(:from) { "Me" }
  let(:to) { "You" }
  let(:amount) { 100 }
  let(:timestamp) { 1449970561 }

  describe "JSON Serializable" do
    let(:txn_json) do
      Ledger::Model::Transaction.from_json({
        from:      from,
        to:        to,
        amount:    amount,
        timestamp: timestamp,
        hash:      hash,
      }.to_json)
    end

    it "should initialize successfully" do
      txn_json.from.must_equal(from)
      txn_json.to.must_equal(to)
      txn_json.amount.must_equal(amount)
      txn_json.timestamp.must_equal(timestamp)
      txn_json.hash.must_equal(hash)
    end
  end

  describe "Construct" do
    let(:txn) do
      Ledger::Model::Transaction.new(
        from: from,
        to: to,
        amount: amount.to_i64
      )
    end

    it "should generate timestamp" do
      txn.timestamp.wont_be_nil
    end

    it "should generate hash" do
      txn.hash.wont_be_nil
    end
  end
end
