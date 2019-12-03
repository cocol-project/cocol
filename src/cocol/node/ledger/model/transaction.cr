require "json"
require "openssl"

module Ledger::Model
  alias TxnHash = String
  alias TxnHashSeed = String

  abstract struct AbstractTransaction
    include JSON::Serializable

    abstract def create_seed : TxnHashSeed

    def calc_hash : TxnHash
      sha = OpenSSL::Digest.new("SHA256")
      sha.update(create_seed)
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
      @hash = calc_hash
    end

    def create_seed : TxnHashSeed
      "#{@from}#{@to}#{@amount}#{@timestamp}"
    end
  end

  struct Stake < AbstractTransaction
    getter staker : String
    getter amount : Int64
    getter hash : TxnHash
    getter timestamp : Int64

    def initialize(@staker, @amount)
      @timestamp = Time.utc.to_unix
      @hash = calc_hash
    end

    def create_seed : TxnHashSeed
      "#{@staker}#{@amount}#{@timestamp}"
    end
  end
end
