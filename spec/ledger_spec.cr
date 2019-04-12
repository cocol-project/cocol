require "./spec_helper.cr"
require "../src/cocol/node/ledger.cr"

describe "Node::Ledger" do
  describe "workflow genesis" do
    Node::Ledger.workflow_genesis_block

    it "prepares ledger state" do
      Node::Ledger::Repo.established_height.should eq(0)
      Node::Ledger::Repo.ledger.size.should eq(1)
      Node::Ledger::Repo.blocks.size.should eq(1)
      Node::Ledger::Repo.orphans.size.should eq(0)
      Node::Ledger::Repo.candidates.size.should eq(0)
    end

    it "created the genesis block" do
      Node::Ledger::Repo.blocks[Node::Ledger::Repo.ledger.last].previous_hash.should eq("Olivia")
    end
  end

  describe "Workflow assign block" do
    height = Node::Ledger::Repo.established_height + 1_u64
    previous_hash = Node::Ledger::Repo.ledger.last
    transactions = Array(Node::Ledger::Model::Transaction).new
    nonce = 12_u64


    block_a = Node::Ledger::Model::Block.new(
      height: height,
      transactions: transactions,
      previous_hash: previous_hash,
      timestamp: Time.utc_now.to_unix,
      nonce: nonce,
      hash: "hash_a"
    )
    block_aa = Node::Ledger::Model::Block.new(
      height: height,
      transactions: transactions,
      previous_hash: previous_hash,
      timestamp: Time.utc_now.to_unix,
      nonce: nonce,
      hash: "hash_aa"
    )

    block_b = Node::Ledger::Model::Block.new(
      height: block_a.height + 1,
      transactions: transactions,
      previous_hash: block_a.hash,
      timestamp: Time.utc_now.to_unix,
      nonce: nonce,
      hash: "hash_b"
    )

    block_c = Node::Ledger::Model::Block.new(
      height: block_b.height + 1,
      transactions: transactions,
      previous_hash: block_b.hash,
      timestamp: Time.utc_now.to_unix,
      nonce: nonce,
      hash: "hash_c"
    )

    block_e = Node::Ledger::Model::Block.new(
      height: block_c.height + 1,
      transactions: transactions,
      previous_hash: block_c.hash,
      timestamp: Time.utc_now.to_unix,
      nonce: nonce,
      hash: "hash_e"
    )

    it "votes current block for candidate" do
      Node::Ledger::Repo.save_block(block_a)
      Node::Ledger.workflow_assign_block(block_a)

      Node::Ledger::Repo.candidates.should contain(block_a.hash)
    end

    it "votes current similar block for candidate" do
      Node::Ledger::Repo.save_block(block_aa)
      Node::Ledger.workflow_assign_block(block_aa)

      Node::Ledger::Repo.candidates.should contain(block_aa.hash)
      Node::Ledger::Repo.candidates.size.should eq(2)
    end

    it "should create an orphan" do
      Node::Ledger::Repo.save_block(block_e)
      Node::Ledger.workflow_assign_block(block_e)

      Node::Ledger::Repo.orphans[block_e.previous_hash]?.should be_truthy
    end

    it "should establish new active block" do
      Node::Ledger::Repo.save_block(block_b)
      Node::Ledger.workflow_assign_block(block_b)

      Node::Ledger::Repo.ledger.last.should eq(block_b.previous_hash)
      Node::Ledger::Repo.candidates.includes?(block_b.previous_hash).should be_falsey
      Node::Ledger::Repo.candidates.includes?(block_b.hash).should be_truthy
      Node::Ledger::Repo.established_height.should eq(block_b.height - 1)
    end

    it "should become new active block" do
      Node::Ledger::Repo.save_block(block_c)
      Node::Ledger.workflow_assign_block(block_c)

      Node::Ledger::Repo.ledger.last.should eq(block_c.hash)
      Node::Ledger::Repo.candidates.includes?(block_c.hash).should be_falsey
      Node::Ledger::Repo.established_height.should eq(block_c.height)
    end

    it "should make orphan a candidate" do
      Node::Ledger::Repo.candidates.includes?(block_e.hash).should be_truthy
      Node::Ledger::Repo.orphans[block_e.previous_hash]?.should be_falsey
    end
  end

  describe "Workflow Mining" do
    new_block_parent = Node::Ledger::Repo.candidates.first
    Node::Ledger.workflow_mine(
      transactions: Node::Ledger::Repo.pending_transactions.values,
      difficulty_bits: 1
    )

    it "it became first candidate" do
      new_block_parent.should eq(Node::Ledger::Repo.ledger.last)
      new_block = Node::Ledger::Repo.blocks[Node::Ledger::Repo.candidates.first]
      new_block.previous_hash.should eq(new_block_parent)
      Node::Ledger::Repo.blocks[Node::Ledger::Repo.candidates.first].height.should eq(Node::Ledger::Repo.blocks[new_block_parent].height + 1)
    end

    txn = Node::Ledger::Model::Transaction.new(
      from: "Olivia",
      to: "Teddyshum",
      amount: 100_f32,
    )
    Node::Ledger::Repo.pending_transactions[txn.hash] = txn

    Node::Ledger.workflow_mine(
      transactions: Node::Ledger::Repo.pending_transactions.values,
      difficulty_bits: 1
    )
    it "deleted used transactions" do
      Node::Ledger::Repo.pending_transactions.empty?.should be_true
    end
  end
end
