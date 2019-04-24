module Node
  extend self

  # should be e2e tested
  def start
    Ledger.workflow_genesis_block

    if !Node.settings.master
      Messenger.establish_network_position
    end
  end

end
