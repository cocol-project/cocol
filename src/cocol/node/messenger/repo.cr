module Messenger
  module Repo
    extend self

    def peers
      @@peers ||= Set(Messenger::Struct::Peer).new
    end

    def known_peers
      @@known_peers ||= Set(Messenger::Struct::Peer).new
    end
  end
end
