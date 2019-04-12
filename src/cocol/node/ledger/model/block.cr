require "openssl"
require "json"
require "big"

require "./transaction"

module Node::Ledger::Model
  ### PoW

  module PoW
    extend self

    alias BlockHash = String

    record Work,
          nonce : UInt64,
          hash : BlockHash
    record BlockData,
          height : UInt64,
          timestamp : Int64,
          transactions : Array(String),
          previous_hash : BlockHash do

      def to_hash_input : String
        "#{height}#{timestamp}#{transactions}#{previous_hash}"
      end
    end

    def self.mine(difficulty_bits : Int32, block_data : BlockData) : Work
      max_nonce = BigInt.new(2) ** BigInt.new(32)
      target = BigInt.new(2) ** BigInt.new(256 - difficulty_bits)
      data = block_data.to_hash_input

      (0..max_nonce).each do |i|
        hash = calculate_hash(i.to_i64, data)
        if BigInt.new(hash, 16) < target
          return Work.new(nonce: i.to_u64, hash: hash)
        end
      end

      raise "max_nonce reached"
    end

    def self.calculate_hash(nonce : Int64, data : String) : BlockHash
      sha = OpenSSL::Digest.new("SHA256")
      sha.update("#{nonce}#{data}")
      sha.hexdigest
    end
  end

  class Block
    include JSON::Serializable
    include Node::Ledger::Model
    include PoW

    getter hash : String
    getter timestamp : Int64
    getter height : UInt64
    getter nonce : UInt64
    getter previous_hash : String
    property transactions : Array(Transaction)

    def initialize(@hash,
                   @timestamp,
                   @height,
                   @nonce,
                   @previous_hash,
                   @transactions)
    end

    def self.new(height : UInt64,
                 transactions : Array(Transaction),
                 previous_hash : String,
                 difficulty_bits : Int32 = 20)

      sleep Random.rand(5.0..6.1)
      block_data = BlockData.new(
        timestamp: Time.utc_now.to_unix,
        height: height,
        previous_hash: previous_hash,
        transactions: transactions.map { |txn| txn.hash }
      )
      work = PoW.mine(difficulty_bits: difficulty_bits,
                             block_data: block_data)

      Block.new(
        hash: work.hash,
        timestamp: block_data.timestamp,
        height: height,
        nonce: work.nonce,
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
        previous_hash: "Olivia",
        transactions: Array(Transaction).new
      )
    end
  end

end
