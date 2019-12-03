post "/transactions" do |env|
  new_txn = Ledger::Model::Transaction.from_json(
    env.request.body.not_nil!)
  if Ledger::Mempool.add(new_txn)
    spawn { Messenger.broadcast to: "/transactions", body: new_txn.to_json }

    if Node.settings.miner
      spawn Event.broadcast(Event.transaction("onTxn", new_txn).to_json)
    end
  end

  new_txn.to_json
end

get "/transactions" do |_env|
  Ledger::Mempool.pending.to_json
end

post "/blocks" do |env|
  new_block = Ledger::Model::Block::Pow.from_json(
    env.request.body.not_nil!)
  if Ledger::Repo.save(block: new_block)
    if Node.settings.port > 4000
      Cocol.logger.info "[Node: #{Node.settings.port}] Height: #{new_block.height} NBits: #{new_block.nbits} Saved: #{new_block.hash}"
    end
    spawn do
      ProbFin.push(block: new_block.hash, parent: new_block.previous_hash)
      Messenger.broadcast to: "/blocks", body: new_block.to_json
      Event.broadcast(Event.update("onInitialUpdate").to_json)
    end
  end
end

get "/blocks" do |_env|
  Ledger::Repo.blocks.values.to_json
end

get "/ledger" do |_env|
  Ledger::Repo.ledger.to_json
end
