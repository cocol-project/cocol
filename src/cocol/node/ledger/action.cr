# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at # http://mozilla.org/MPL/2.0/

module Ledger::Action
  alias TxnHash = String

  struct Signature
    include JSON::Serializable

    getter v : String
    getter r : String
    getter s : String

    def initialize(@v, @r, @s)
    end
  end

  abstract struct Abstract
    include JSON::Serializable

    getter hash : TxnHash
    getter amount : UInt64
    getter timestamp : Int64
    @[JSON::Field(emit_null: true)]
    property sig : Signature?

    private def calc_hash(*seed) : TxnHash
      sha = OpenSSL::Digest.new("SHA256")
      sha.update(seed.join(""))
      sha.hexdigest
    end
  end

  struct Transaction < Abstract
    getter from : String
    getter to : String

    def initialize(@from, @to, @amount)
      @timestamp = Time.utc.to_unix
      @hash = calc_hash(from, to, amount, timestamp)
    end
  end

  struct Stake < Abstract
    getter staker : String

    def initialize(@staker, @amount)
      @timestamp = Time.utc.to_unix
      @hash = calc_hash(staker, amount, timestamp)
    end
  end
end
