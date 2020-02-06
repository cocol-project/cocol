# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at # http://mozilla.org/MPL/2.0/

require "./spec_helper"

describe Ledger::Pow do
  let(:txn) do
    Ledger::Action::Transaction.new(
      from: "me",
      to: "you",
      amount: 1_u64
    )
  end
  let(:transactions) { [txn] of Ledger::Action::Transaction }
  let(:block) { Ledger::Pow.mine(transactions) }

  let(:invalid_block) do
    Ledger::Block::Pow.new(
      hash: "somethinginvalid",
      timestamp: Time.utc.to_unix,
      height: 12_u64,
      nonce: 123_u64,
      nbits: Ledger::Block::Pow::MIN_NBITS,
      previous_hash: "somethinginvalidagain",
      transactions: Array(Ledger::Action::Transaction).new,
      coinbase: Ledger::Block::Coinbase.new("Me")
    )
  end

  describe "Genesis" do
    it "created the genesis block" do
      Ledger::Pow.genesis
      Ledger::Repo.blocks[Ledger::Repo.block_at_height[0_u64]].previous_hash.must_equal("Olivia")
    end
  end

  describe "Mine" do
    it "mines a block" do
      block.transactions.must_equal(transactions)
      block.nonce.wont_be_nil
      block.nbits.wont_be_nil
      block.timestamp.wont_be_nil
    end
  end

  describe "Validation" do
    it "validates a block" do
      Ledger::Pow.valid?(block: block).must_equal(true)
    end

    it "rejects invalid block" do
      Ledger::Pow.valid?(block: invalid_block).must_equal(false)
    end
  end
end

describe Ledger::Pos do
  let(:block) do
    Ledger::Block::Pos.new(
      height: 12_u64,
      transactions: Array(Ledger::Action::Transaction).new,
      stakes: Array(Ledger::Action::Stake).new,
      previous_hash: "bogus",
      coinbase: Ledger::Block::Coinbase.new("bogus")
    )
  end

  let(:invalid_block) do
    Ledger::Block::Pos.new(
      hash: "bogus",
      timestamp: Time.utc.to_unix,
      height: 12_u64,
      transactions: Array(Ledger::Action::Transaction).new,
      stakes: Array(Ledger::Action::Stake).new,
      previous_hash: "bogus",
      coinbase: Ledger::Block::Coinbase.new("bogus")
    )
  end

  it "validates block hash" do
    Ledger::Pos.valid?(block: block).must_equal(true)
  end

  it "rejects invalid block hash" do
    Ledger::Pos.valid?(block: invalid_block).must_equal(false)
  end
end
