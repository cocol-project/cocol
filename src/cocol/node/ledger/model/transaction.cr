module Ledger::Model
  alias TxnHash = String
  alias TxnHashSeed = String

  abstract struct AbstractTransaction
    include JSON::Serializable

    private def calc_hash(*seed) : TxnHash
      sha = OpenSSL::Digest.new("SHA256")
      sha.update(seed.join(""))
      sha.hexdigest
    end
  end

  struct Transaction < AbstractTransaction
    getter from : String
    getter to : String
    getter amount : Int64
    getter hash : TxnHash
    getter timestamp : Int64

    def initialize(@from, @to, @amount)
      @timestamp = Time.utc.to_unix
      @hash = calc_hash(from, to, amount, timestamp)
    end
  end

  struct Stake < AbstractTransaction
    getter staker : String
    getter amount : Int64
    getter hash : TxnHash
    getter timestamp : Int64

    def initialize(@staker, @amount)
      @timestamp = Time.utc.to_unix
      @hash = calc_hash(staker, amount, timestamp)
    end
  end
end
