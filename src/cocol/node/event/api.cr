# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at # http://mozilla.org/MPL/2.0/

ws "/events" do |socket|
  Event.add_socket socket
  spawn Event.broadcast(Event.update("onInitialUpdate").to_json)

  socket.on_close do
    Event.del_socket socket
  end
end
