module Messenger::Struct
  struct Peer
    include JSON::Serializable

    property ident : UUID?
    property host : String
    property port : UInt32

    def initialize(@ident, @port, @host)
    end
  end
end
