require "./spec_helper"

describe "Ledger::Action::Transaction" do
  let(:hash) { "c9b0f2181f2783594c8c30f79ef8ff6231494ab50013ed0bb0fc2cd75408f791" }
  let(:from) { "Me" }
  let(:to) { "You" }
  let(:amount) { 100_u64 }
  let(:timestamp) { 1449970561 }
  let(:signature) { Ledger::Action::Signature.new(
    v: "034ce3a20d210dc22b79a0944a9b9ef29f3aa50730cc27be7ec4adc601cbcb7372",
    r: "70189975654209893549254487705918808402318817289942319050850973295297592779325",
    s: "56643761485509572745767837990785422271240332652515523415468197818355438975767"
  ) }

  describe "JSON Serializable" do
    let(:txn_json) do
      Ledger::Action::Transaction.from_json({
        from:      from,
        to:        to,
        amount:    amount,
        timestamp: timestamp,
        hash:      hash,
        sig:       signature,
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
      Ledger::Action::Transaction.new(
        from: from,
        to: to,
        amount: amount
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
