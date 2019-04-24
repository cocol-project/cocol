require "json"
require "openssl"

module Ledger::Model
  class Transaction
    include JSON::Serializable

    property from : String
    property to : String
    property amount : Float32
    getter hash : String
    getter timestamp : Int64

    def initialize(@from, @to, @amount)
      @timestamp = Time.utc_now.to_unix
      @hash = calc_hash
    end

    private def calc_hash : String
      sha = OpenSSL::Digest.new("SHA256")
      sha.update("#{@from}#{@to}#{@amount}")
      sha.hexdigest
    end
  end
end
