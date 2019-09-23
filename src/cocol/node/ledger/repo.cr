require "./model/*"

module Ledger
  module Repo
    extend self

    include Ledger::Model

    alias ParentHash = String
    alias BlockHash = String
    alias Height = UInt64
    alias TxnHash = String

    def blocks : Hash(BlockHash, Model::Block)
      @@blocks ||= Hash(BlockHash, Model::Block).new
    end

    def ledger : Array(BlockHash)
      @@ledger ||= Array(BlockHash).new
    end

    def height : Hash(Height, BlockHash)
      @@height ||= Hash(Height, BlockHash).new
    end

    def candidates : Array(BlockHash)
      @@candidates ||= Array(BlockHash).new
    end

    def orphans : Hash(ParentHash, BlockHash)
      @@orphans ||= Hash(ParentHash, BlockHash).new
    end

    # ===

    def active_block : (Nil | Model::Block)
      if ledger.size > 0
        blocks[ledger.last]
      else
        nil
      end
    end

    def established_height : UInt64
      @@established_height ||= 0_u64
    end

    def established_height(plus : UInt64) : UInt64
      @@established_height = self.established_height + plus
    end

    def established_height=(height : UInt64) : UInt64
      @@established_height = height
    end

    def save_block(block : Model::Block) : Bool
      return false if self.blocks[block.hash]?
      return false if self.height[block.height]?
      return false if self.candidates.any? do |c|
                        self.blocks[c].height == block.height
                      end

      # new block add to blocks
      self.blocks[block.hash] = block
      self.height[block.height] = block.hash
      true
    end

    def establish(block_hash : BlockHash, height : Height) : Void
      self.ledger << block_hash
      self.established_height(plus: 1_u64)
    end
  end
end
