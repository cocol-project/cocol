require "uuid"

module Node
  class Settings
    getter ident : UUID
    property port : Int32 = 3000
    property max_connections : Int32 = 20
    property miner : Bool = false
    property master : Bool = false

    def initialize
      @ident = UUID.random
    end
  end

  def self.settings
    @@settings ||= Settings.new
  end
end
