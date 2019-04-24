post "/transactions" do |env|
  new_txn = Ledger::Model::Transaction.from_json(
    env.request.body.not_nil!)
  if Ledger::Repo.save_transaction(new_txn)
    spawn { Messenger.broadcast to: "/transactions", body: new_txn.to_json }

    if Node.settings.miner
      spawn Event.broadcast(Event.transaction("onTxn", new_txn).to_json)
    end
  end

  new_txn.to_json
end

get "/transactions" do |_env|
  Ledger::Repo.pending_transactions.to_json
end

post "/blocks" do |env|
  new_block = Ledger::Model::Block.from_json(
    env.request.body.not_nil!)
  if Ledger::Repo.save_block(new_block)
    spawn do
      Ledger.workflow_assign_block(new_block)
      Messenger.broadcast to: "/blocks", body: new_block.to_json
      spawn Event.broadcast(Event.update("onInitialUpdate").to_json)
    end
  end
end

get "/blocks" do |_env|
  Ledger::Repo.blocks.values.to_json
end

get "/ledger" do |_env|
  Ledger::Repo.ledger.to_json
end
get "/candidates" do |_env|
  Ledger::Repo.candidates.to_json
end
get "/orphans" do |_env|
  Ledger::Repo.orphans.to_json
end
