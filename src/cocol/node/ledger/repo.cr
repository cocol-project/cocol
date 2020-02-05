require "./block"

module Ledger
  module Repo
    extend self

    alias BlockHash = String
    alias Block = (Ledger::Block::Pow | Ledger::Block::Pos)

    def blocks
      @@blocks ||= Hash(BlockHash, Block).new
    end

    def ledger
      @@ledger ||= Array(BlockHash).new
    end

    def block_at_height
      @@block_at_height ||= Hash(UInt64, BlockHash).new
    end

    # ===

    def ledger_last : Block
      blocks[ledger.last]
    end

    def save(block : Block) : Bool
      return false if self.blocks[block.hash]?

      self.blocks[block.hash] = block

      true
    end

    def finalize(block hash : BlockHash) : Bool
      finalized_block = self.blocks[hash]
      return false if self.block_at_height[finalized_block.height]?

      self.ledger << hash
      self.block_at_height[finalized_block.height] = hash

      true
    end
  end
end
