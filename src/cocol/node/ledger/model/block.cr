module Ledger::Model
  module Block
    alias BlockHash = String
    alias BlockHashSeed = String

    abstract struct Base
      include JSON::Serializable
      include Ledger::Model

      getter hash : String
      getter timestamp : Int64
      getter height : UInt64
      getter previous_hash : String

      private abstract def hash_seed : BlockHashSeed
      private abstract def calc_hash
    end

    struct Pos < Base
      getter transactions : Array(Transaction)
      getter stakes : Array(Stake)
      getter miner : String

      def initialize(@hash,
                     @timestamp,
                     @height,
                     @previous_hash,
                     @transactions,
                     @stakes,
                     @miner)
      end

      def initialize(@height,
                     @transactions,
                     @stakes,
                     @previous_hash,
                     @miner)
        @timestamp = Time.utc.to_unix
        @hash = calc_hash
      end

      private def hash_seed : BlockHashSeed
        transactions = @transactions.map { |txn| txn.hash }.join("")
        "#{@height}#{@timestamp}#{transactions}#{@previous_hash}"
      end

      private def calc_hash
        sha256 = OpenSSL::Digest.new("SHA256")
        sha256.update(hash_seed())
        sha256.hexdigest
      end
    end

    struct Pow < Base
      MIN_NBITS = "20000010"

      getter nonce : UInt64
      getter nbits : String
      getter transactions : Array(Transaction)

      def initialize(@hash,
                     @timestamp,
                     @height,
                     @nonce,
                     @nbits,
                     @previous_hash,
                     @transactions)
      end

      def initialize(@height,
                     @transactions,
                     @previous_hash,
                     @nbits)
        @timestamp = Time.utc.to_unix

        pow = calc_hash()
        @hash = pow.hash
        @nonce = pow.nonce
      end

      private def hash_seed : BlockHashSeed
        transactions = @transactions.map { |txn| txn.hash }.join("")
        "#{@height}#{@timestamp}#{transactions}#{@previous_hash}"
      end

      private def calc_hash
        BTCPoW.mine(difficulty: @nbits, for: hash_seed())
      end
    end
  end
end
