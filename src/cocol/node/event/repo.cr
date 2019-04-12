require "socket"

module Event
  module Repo
    extend self

    def websockets
      @@websockets ||= Array(HTTP::WebSocket).new
    end
  end
end
