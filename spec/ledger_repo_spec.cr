require "./spec_helper"

describe "Ledger::Repo" do
  let(:block_a) do
    Ledger::Model::Block::Pos.new(
      height: 0_u64,
      previous_hash: "Olivia",
      transactions: Array(Ledger::Model::Transaction).new,
      stakes: Array(Ledger::Model::Stake).new,
      miner: "3000"
    )
  end

  let(:block_b) do
    Ledger::Model::Block::Pos.new(
      height: 1_u64,
      previous_hash: block_a.hash,
      transactions: Array(Ledger::Model::Transaction).new,
      stakes: Array(Ledger::Model::Stake).new,
      miner: "3000"
    )
  end

  describe "saving blocks" do
    before do
      clear_ledger_repo
    end

    it "saves a new block" do
      saved = Ledger::Repo.save(block: block_a)

      # saved.should be_true
      saved.must_equal(true)
      Ledger::Repo.blocks[block_a.hash]?.must_equal(block_a)
    end

    it "rejects saving if it's a known block" do
      Ledger::Repo.save(block: block_a)
      saved = Ledger::Repo.save(block: block_a)

      saved.must_equal(false)
    end
  end

  describe "finality" do
    before do
      clear_ledger_repo
      Ledger::Repo.save(block: block_a)
    end

    it "finalizes block" do
      Ledger::Repo.save(block: block_b)
      Ledger::Repo.finalize block: block_a.hash
      Ledger::Repo.finalize block: block_b.hash

      Ledger::Repo.ledger_last.must_equal(block_b)

      Ledger::Repo.block_at_height[0_u64].must_equal(block_a.hash)
      Ledger::Repo.block_at_height[1_u64].must_equal(block_b.hash)
    end
  end
end
