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
