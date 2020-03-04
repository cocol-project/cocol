# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at # http://mozilla.org/MPL/2.0/

module Messenger::Struct
  struct Peer
    include JSON::Serializable

    property ident : String?
    property host : String
    property port : UInt32

    def initialize(@port, @host)
    end

    def initialize(@ident, @port, @host)
    end
  end
end
