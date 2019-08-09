require "openssl"
require "json"
require "big"

require "./transaction"

require "btcpow"

module Ledger
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
                   difficulty : String)
        #sleep Random.rand(5.0..6.1)
        block_data = BlockData.new(
          timestamp: Time.utc_now.to_unix,
          height: height,
          previous_hash: previous_hash,
          randr: Random.rand(0_u16..UInt16::MAX),
          transactions: transactions.map { |txn| txn.hash }
        )
        Cocol.logger.info("Miner: #{Node.settings.port} Difficulty: #{difficulty}")
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
