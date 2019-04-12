ws "/events" do |socket|
  Event.add_socket socket
  spawn Event.broadcast(Event.update("onInitialUpdate").to_json)

  socket.on_close do
    Event.del_socket socket
  end
end
