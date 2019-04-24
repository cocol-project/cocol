require "./spec_helper.cr"
require "../src/cocol/node/ledger.cr"

describe "Ledger" do
  describe "workflow genesis" do
    Ledger.workflow_genesis_block

    it "prepares ledger state" do
      Ledger::Repo.established_height.should eq(0)
      Ledger::Repo.ledger.size.should eq(1)
      Ledger::Repo.blocks.size.should eq(1)
      Ledger::Repo.orphans.size.should eq(0)
      Ledger::Repo.candidates.size.should eq(0)
    end

    it "created the genesis block" do
      Ledger::Repo.blocks[Ledger::Repo.ledger.last].previous_hash.should eq("Olivia")
    end
  end

  describe "Workflow assign block" do
    height = Ledger::Repo.established_height + 1_u64
    previous_hash = Ledger::Repo.ledger.last
    transactions = Array(Ledger::Model::Transaction).new
    nonce = 12_u64


    block_a = Ledger::Model::Block.new(
      height: height,
      transactions: transactions,
      previous_hash: previous_hash,
      timestamp: Time.utc_now.to_unix,
      nonce: nonce,
      hash: "hash_a"
    )
    block_aa = Ledger::Model::Block.new(
      height: height,
      transactions: transactions,
      previous_hash: previous_hash,
      timestamp: Time.utc_now.to_unix,
      nonce: nonce,
      hash: "hash_aa"
    )

    block_b = Ledger::Model::Block.new(
      height: block_a.height + 1,
      transactions: transactions,
      previous_hash: block_a.hash,
      timestamp: Time.utc_now.to_unix,
      nonce: nonce,
      hash: "hash_b"
    )

    block_c = Ledger::Model::Block.new(
      height: block_b.height + 1,
      transactions: transactions,
      previous_hash: block_b.hash,
      timestamp: Time.utc_now.to_unix,
      nonce: nonce,
      hash: "hash_c"
    )

    block_e = Ledger::Model::Block.new(
      height: block_c.height + 1,
      transactions: transactions,
      previous_hash: block_c.hash,
      timestamp: Time.utc_now.to_unix,
      nonce: nonce,
      hash: "hash_e"
    )

    it "votes current block for candidate" do
      Ledger::Repo.save_block(block_a)
      Ledger.workflow_assign_block(block_a)

      Ledger::Repo.candidates.should contain(block_a.hash)
    end

    it "votes current similar block for candidate" do
      Ledger::Repo.save_block(block_aa)
      Ledger.workflow_assign_block(block_aa)

      Ledger::Repo.candidates.should contain(block_aa.hash)
      Ledger::Repo.candidates.size.should eq(2)
    end

    it "should create an orphan" do
      Ledger::Repo.save_block(block_e)
      Ledger.workflow_assign_block(block_e)

      Ledger::Repo.orphans[block_e.previous_hash]?.should be_truthy
    end

    it "should establish new active block" do
      Ledger::Repo.save_block(block_b)
      Ledger.workflow_assign_block(block_b)

      Ledger::Repo.ledger.last.should eq(block_b.previous_hash)
      Ledger::Repo.candidates.includes?(block_b.previous_hash).should be_falsey
      Ledger::Repo.candidates.includes?(block_b.hash).should be_truthy
      Ledger::Repo.established_height.should eq(block_b.height - 1)
    end

    it "should become new active block" do
      Ledger::Repo.save_block(block_c)
      Ledger.workflow_assign_block(block_c)

      Ledger::Repo.ledger.last.should eq(block_c.hash)
      Ledger::Repo.candidates.includes?(block_c.hash).should be_falsey
      Ledger::Repo.established_height.should eq(block_c.height)
    end

    it "should make orphan a candidate" do
      Ledger::Repo.candidates.includes?(block_e.hash).should be_truthy
      Ledger::Repo.orphans[block_e.previous_hash]?.should be_falsey
    end
  end

  describe "Workflow Mining" do
    new_block_parent = Ledger::Repo.candidates.first
    Ledger.workflow_mine(
      transactions: Ledger::Repo.pending_transactions.values,
      difficulty_bits: 1
    )

    it "it became first candidate" do
      new_block_parent.should eq(Ledger::Repo.ledger.last)
      new_block = Ledger::Repo.blocks[Ledger::Repo.candidates.first]
      new_block.previous_hash.should eq(new_block_parent)
      Ledger::Repo.blocks[Ledger::Repo.candidates.first].height.should eq(Ledger::Repo.blocks[new_block_parent].height + 1)
    end

    txn = Ledger::Model::Transaction.new(
      from: "Olivia",
      to: "Teddyshum",
      amount: 100_f32,
    )
    Ledger::Repo.pending_transactions[txn.hash] = txn

    Ledger.workflow_mine(
      transactions: Ledger::Repo.pending_transactions.values,
      difficulty_bits: 1
    )
    it "deleted used transactions" do
      Ledger::Repo.pending_transactions.empty?.should be_true
    end
  end
end
