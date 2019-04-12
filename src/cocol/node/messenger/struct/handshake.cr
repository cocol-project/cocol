require "json"
require "uuid"
require "uuid/json"

module Messenger::Struct
  struct Handshake
    include JSON::Serializable

    property ident : UUID
    property port : Int32

    def initialize(@ident, @port)
    end
  end
end
