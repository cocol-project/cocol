module Node
  class Settings
    getter ident : UUID
    property port : Int32
    property max_connections : Int32
    property miner : Bool
    property master : Bool
    property ip_addr : String

    def initialize
      @ident = UUID.random
    end

    def peer_info
      {ip_addr: @ip_addr, port: @port, ident: @ident}
    end
  end

  def self.settings
    @@settings ||= Settings.new
  end
end
