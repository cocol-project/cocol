require "../src/deps"
require "minitest/autorun"

def clear_ledger_repo
  Ledger::Repo.blocks.clear
  Ledger::Repo.block_at_height.clear
  Ledger::Repo.ledger.clear
end
