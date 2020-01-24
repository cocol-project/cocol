# --- Transactions

post "/transactions" do |env|
  begin
    new_txn = Ledger::Model::Transaction.from_json(
      env.request.body.not_nil!)
  rescue
    halt(
      env,
      status_code: 400,
      response: "Bad Request"
    )
  end
  halt(
    env,
    status_code: 422,
    response: "Invalid Transaction"
  ) if !Ledger::Util.valid?(transaction: new_txn)

  if Ledger::Mempool.add(new_txn)
    spawn { Messenger.broadcast to: "/transactions", body: new_txn.to_json }

    if Node.settings.miner
      spawn Event.broadcast(Event.transaction("onTxn", new_txn).to_json)
    end
  end

  new_txn.to_json
end

get "/transactions" do
  Ledger::Mempool.pending.to_json
end

# --- Blocks

post "/blocks/pow" do |env|
  begin
    new_block = Ledger::Model::Block::Pow.from_json(
      env.request.body.not_nil!)
  rescue
    halt(
      env,
      status_code: 400,
      response: "Bad Request"
    )
  end

  if Ledger::Repo.save(block: new_block)
    if Node.settings.port > 4000
      Cocol.logger.info "Height: #{new_block.height} NBits: #{new_block.nbits} Saved: #{new_block.hash}"
    end
    spawn do
      ProbFin.push(block: new_block.hash, parent: new_block.previous_hash)
      Messenger.broadcast to: "/blocks", body: new_block.to_json
      Event.broadcast(Event.update("onInitialUpdate").to_json)
    end
  end
end

post "/blocks/pos" do |env|
  new_block = Ledger::Model::Block::Pos.from_json(
    env.request.body.not_nil!)
  Ledger::Pos.validate new_block
end

get "/blocks" do
  Ledger::Repo.blocks.values.to_json
end

# --- Ledger

get "/ledger" do
  Ledger::Repo.ledger.to_json
end
