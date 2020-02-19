module Messenger::Struct
  struct Peer
    include JSON::Serializable

    property ident : UUID?
    property ip_addr : String
    property port : UInt32

    def initialize(@ident, @port, @ip_addr)
    end
  end
end
