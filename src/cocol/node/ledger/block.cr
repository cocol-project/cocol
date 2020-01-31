require "./action"

module Ledger::Block
  alias BlockHash = String
  alias BlockHashSeed = String

  struct Coinbase
    include JSON::Serializable

    getter miner : String
    getter reward : UInt64

    def initialize(@miner)
      @reward = 5_u64
    end
  end

  abstract struct Base
    include JSON::Serializable
    include Ledger::Action

    getter hash : String
    getter timestamp : Int64
    getter height : UInt64
    getter previous_hash : String
    getter coinbase : Coinbase
    getter transactions : Array(Transaction)

    private abstract def hash_seed : BlockHashSeed
    private abstract def calc_hash
  end

  struct Pos < Base
    getter stakes : Array(Stake)

    def initialize(@hash,
                   @timestamp,
                   @height,
                   @previous_hash,
                   @transactions,
                   @stakes,
                   @coinbase)
    end

    def initialize(@height,
                   @transactions,
                   @stakes,
                   @previous_hash,
                   @coinbase)
      @timestamp = Time.utc.to_unix
      @hash = calc_hash
    end

    private def hash_seed : BlockHashSeed
      transactions = @transactions.map { |txn| txn.hash }.join("")
      "#{@height}#{@timestamp}#{transactions}#{@previous_hash}#{@coinbase}"
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

    def initialize(@hash,
                   @timestamp,
                   @height,
                   @nonce,
                   @nbits,
                   @previous_hash,
                   @transactions,
                   @coinbase)
    end

    def initialize(@height,
                   @transactions,
                   @previous_hash,
                   @nbits,
                   @coinbase)
      @timestamp = Time.utc.to_unix

      pow = calc_hash()
      @hash = pow.hash
      @nonce = pow.nonce
    end

    private def hash_seed : BlockHashSeed
      transactions = @transactions.map { |txn| txn.hash }.join("")
      "#{@height}#{@timestamp}#{transactions}#{@previous_hash}#{@coinbase}"
    end

    private def calc_hash
      CCL::Pow.mine(difficulty: @nbits, for: hash_seed())
    end
  end
end
