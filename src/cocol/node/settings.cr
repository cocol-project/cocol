require "uuid"

module Node
  class Settings
    # TODO: Use ..::Struct::Node
    property ident : UUID = UUID.random
    property port : Int32 = 3000
    property max_connections : Int32 = 20
    property miner : Bool = false
    property master : Bool = false
  end

  def self.settings
    @@settings ||= Settings.new
  end
end
