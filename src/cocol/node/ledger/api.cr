# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at # http://mozilla.org/MPL/2.0/

# --- Transactions
post "/transactions" do |env|
  begin
    new_txn = Ledger::Action::Transaction.from_json(
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
    spawn { Messenger::Action::PropagateTransaction.call(new_txn) }

    if Node.settings.miner
      spawn Event.broadcast(Event.transaction("onTxn", new_txn).to_json)
    end
  end

  new_txn.hash
end

get "/transactions/:hash" do |env|
  Ledger::Mempool.pending[env.params.url["hash"]].to_json
end

get "/transactions" do
  Ledger::Mempool.pending.to_json
end

# --- Blocks
post "/blocks/pow" do |env|
  begin
    new_block = Ledger::Block::Pow.from_json(
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
    response: "Invalid Block"
  ) if !Ledger::Pow.valid?(block: new_block)

  if Ledger::Repo.save(block: new_block)
    Cocol.logger.info "Height: #{new_block.height} NBits: #{new_block.nbits} Hash: #{new_block.hash}"
    spawn do
      ProbFin.push(block: new_block.hash, parent: new_block.previous_hash)
      Messenger::Action::Base.broadcast to: "/blocks", body: new_block.to_json
      Event.broadcast(Event.update("onInitialUpdate").to_json)
    end
  end
end

post "/blocks/pos" do |env|
  begin
    new_block = Ledger::Block::Pos.from_json(
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
    response: "Invalid Block"
  ) if !Ledger::Pos.valid?(block: new_block)

  Ledger::Pos.validate new_block
end

get "/inventory/:best_hash" do |env|
  Ledger::Inventory.call(env.params.url["best_hash"]).to_json
end

get "/blocks/:hash" do |env|
  block = Ledger::Repo.blocks[env.params.url["hash"]]?
  halt(
    env,
    status_code: 404,
    response: "Not found"
  ) if block.nil?

  block.to_json
end

# --- Ledger
get "/ledger" do
  Ledger::Repo.ledger.to_json
end
