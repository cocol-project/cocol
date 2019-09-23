require "json"
require "openssl"

module Ledger::Model
  struct Transaction
    include JSON::Serializable

    alias TxnHash = String

    property from : String
    property to : String
    property amount : Float32
    getter hash : TxnHash
    getter timestamp : Int64

    def initialize(@from, @to, @amount)
      @timestamp = Time.utc_now.to_unix
      @hash = calc_hash
    end

    private def calc_hash : TxnHash
      sha = OpenSSL::Digest.new("SHA256")
      sha.update("#{@from}#{@to}#{@amount}#{@timestamp}")
      sha.hexdigest
    end
  end
end
