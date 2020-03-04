# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at # http://mozilla.org/MPL/2.0/

module Node
  class Settings
    getter ident : String
    property host : String = "localhost"
    property port : UInt32 = 3001_u32
    property max_connections : UInt16 = 5_u16
    property miner : Bool = false
    property miner_address : String?
    property master : Bool = false

    def initialize
      @ident = Random::Secure.base64(6)
    end

    def peer_info
      {host: @host, port: @port, ident: @ident}
    end
  end

  def self.settings
    @@settings ||= Settings.new
  end
end
