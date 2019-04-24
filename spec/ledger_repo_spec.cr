require "spec"
require "../src/cocol/node/ledger/repo.cr"

describe "Ledger::Repo" do

  context "Blocks" do
    block_a = Ledger::Model::Block.genesis

    it "saves a new block" do
      saved = Ledger::Repo.save_block(block_a)

      saved.should be_true
      Ledger::Repo.blocks[block_a.hash]?.should be(block_a)
    end

    it "rejects saving if it's a known block" do
      saved = Ledger::Repo.save_block(block_a)

      saved.should be_false
    end

    it "establishes given block" do
      Ledger::Repo.establish(block_a.hash)

      Ledger::Repo.ledger.should contain(block_a.hash)
      Ledger::Repo.established_height.should eq(1)
    end
  end

  context "Transaction" do
    txn = Ledger::Model::Transaction.new(
      from: "Olivia",
      to: "Teddyshum",
      amount: 100_f32
    )

    it "saves to pending transactions" do
      saved = Ledger::Repo.save_transaction(txn)

      saved.should be_true
      Ledger::Repo.pending_transactions.empty?.should be_false
    end

    it "rejects if it's a known transaction" do
      saved = Ledger::Repo.save_transaction(txn)

      saved.should be_false
    end

    it "deletes transactions" do
      Ledger::Repo.delete_transactions([txn])

      Ledger::Repo.pending_transactions.empty?.should be_true
    end
  end
end
