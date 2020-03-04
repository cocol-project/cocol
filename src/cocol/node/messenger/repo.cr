# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at # http://mozilla.org/MPL/2.0/

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
