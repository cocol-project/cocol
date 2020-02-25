module Node
  class Settings
    getter ident : UUID
    property host : String = "localhost"
    property port : UInt32 = 3001_u32
    property max_connections : UInt16 = 5_u16
    property miner : Bool = false
    property master : Bool = false

    def initialize
      @ident = UUID.random
    end

    def peer_info
      {host: @host, port: @port, ident: @ident}
    end
  end

  def self.settings
    @@settings ||= Settings.new
  end
end
