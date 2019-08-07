require "openssl"
require "json"
require "big"

require "./transaction"

require "btcpow"

module Ledger
  # ## PoW

  # module PoW
  #   extend self

  #   record Work,
  #     nonce : UInt64,
  #     hash : BlockHash

  #   def self.mine(difficulty_bits : Int32, block_data : BlockData) : Work
  #     max_nonce = BigInt.new(2) ** BigInt.new(32)
  #     target = BigInt.new(2) ** BigInt.new(256 - difficulty_bits)
  #     data = block_data.to_hash_input

  #     (0..max_nonce).each do |i|
  #       hash = calculate_hash(i.to_i64, data)
  #       if BigInt.new(hash, 16) < target
  #         return Work.new(nonce: i.to_u64, hash: hash)
  #       end
  #     end

  #     raise "max_nonce reached"
  #   end

  #   def self.calculate_hash(nonce : Int64, data : String) : BlockHash
  #     sha = OpenSSL::Digest.new("SHA256")
  #     sha.update("#{nonce}#{data}")
  #     sha.hexdigest
  #   end
  # end

  module Model
    class Block
      MIN_NBITS = "20000010"

      alias BlockHash = String

      include JSON::Serializable
      include Ledger::Model

      getter hash : String
      getter timestamp : Int64
      getter height : UInt64
      getter nonce : UInt64
      getter nbits : String
      getter randr : UInt16
      getter previous_hash : String
      property transactions : Array(Transaction)

      record BlockData,
        height : UInt64,
        timestamp : Int64,
        transactions : Array(String),
        randr : UInt16,
        previous_hash : BlockHash do
        def to_input : String
          "#{height}#{timestamp}#{transactions}#{previous_hash}#{randr}"
        end
      end

      def initialize(@hash,
                     @timestamp,
                     @height,
                     @nonce,
                     @nbits,
                     @randr,
                     @previous_hash,
                     @transactions)
      end

      def self.new(height : UInt64,
                   transactions : Array(Transaction),
                   previous_hash : String,
                   difficulty : String = MIN_NBITS)
        #sleep Random.rand(5.0..6.1)
        block_data = BlockData.new(
          timestamp: Time.utc_now.to_unix,
          height: height,
          previous_hash: previous_hash,
          randr: Random.rand(0_u16..UInt16::MAX),
          transactions: transactions.map { |txn| txn.hash }
        )
        work = BTCPoW.mine(difficulty: difficulty,
          for: block_data.to_input)

        Block.new(
          hash: work.hash,
          timestamp: block_data.timestamp,
          height: height,
          nonce: work.nonce,
          randr: block_data.randr,
          nbits: difficulty,
          previous_hash: previous_hash,
          transactions: transactions
        )
      end

      def self.genesis
        Block.new(
          hash: "00f82f15d9fee292860b2a37183d769efd3b617451c04017f700238fd472e8bb",
          timestamp: 1449970561_i64,
          height: 0_u64,
          nonce: 144_u64,
          nbits: MIN_NBITS,
          randr: Random.rand(0_u16..UInt16::MAX),
          previous_hash: "Olivia",
          transactions: Array(Transaction).new
        )
      end
    end
  end
end
