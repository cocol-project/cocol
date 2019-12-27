module Messenger::Struct
  struct Peer
    include JSON::Serializable

    @[JSON::Field(default: "localhost")]
    property ip_addr : String

    property handshake : Messenger::Struct::Handshake

    def initialize(@handshake, @ip_addr = "localhost")
    end
  end
end
