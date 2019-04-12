require "spec"
require "../src/cocol/node/ledger/repo.cr"

describe "Node::Ledger::Repo" do

  context "Blocks" do
    block_a = Node::Ledger::Model::Block.genesis

    it "saves a new block" do
      saved = Node::Ledger::Repo.save_block(block_a)

      saved.should be_true
      Node::Ledger::Repo.blocks[block_a.hash]?.should be(block_a)
    end

    it "rejects saving if it's a known block" do
      saved = Node::Ledger::Repo.save_block(block_a)

      saved.should be_false
    end

    it "establishes given block" do
      Node::Ledger::Repo.establish(block_a.hash)

      Node::Ledger::Repo.ledger.should contain(block_a.hash)
      Node::Ledger::Repo.established_height.should eq(1)
    end
  end

  context "Transaction" do
    txn = Node::Ledger::Model::Transaction.new(
      from: "Olivia",
      to: "Teddyshum",
      amount: 100_f32
    )

    it "saves to pending transactions" do
      saved = Node::Ledger::Repo.save_transaction(txn)

      saved.should be_true
      Node::Ledger::Repo.pending_transactions.empty?.should be_false
    end

    it "rejects if it's a known transaction" do
      saved = Node::Ledger::Repo.save_transaction(txn)

      saved.should be_false
    end

    it "deletes transactions" do
      Node::Ledger::Repo.delete_transactions([txn])

      Node::Ledger::Repo.pending_transactions.empty?.should be_true
    end
  end
end
