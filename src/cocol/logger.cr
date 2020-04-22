# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at # http://mozilla.org/MPL/2.0/

require "log"

module Cocol
  extend self

  def logger
    Log.builder.bind "*", :debug, Log::IOBackend.new

    @@logger ||= Log.for(
      "#{Node.settings.ident}@#{Node.settings.host}:#{Node.settings.port}"
    )
  end
end
