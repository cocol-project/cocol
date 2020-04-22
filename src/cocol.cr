# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at # http://mozilla.org/MPL/2.0/

require "./deps"

module Cocol
  module App
    module Api
      extend self

      def run(port : UInt32)
        before_all do |env|
          env.response.content_type = "application/json"
          env.response.headers["Allow"] = "HEAD,GET,PUT,POST,DELETE,OPTIONS"
          env.response.headers["Access-Control-Allow-Origin"] = "*"
          env.response.headers["Access-Control-Allow-Headers"] =
            "X-Requested-With, X-HTTP-Method-Override, Content-Type, Cache-Control, Accept"
        end

        logging false
        Kemal.run(port: port.to_i32, args: nil)
      end
    end

    module Miner
      extend self

      # TODO: refactor me https://gph.is/1cO1G6K
      def run
        chan = Channel(Nil).new
        pending_transactions = Ledger::Mempool.pending.values

        spawn do
          Ledger::Pow.mine(pending_transactions)
          chan.send(nil)
        end

        chan.receive
        Ledger::Mempool.remove(pending_transactions)
        Miner.run
      end
    end
  end

  class Command < Clim
    main do
      desc "Cocol Client - minimal blockchain testbed"
      usage "cocol [options] [arguments] ..."
      version "Version 0.3.0"
      option "-h HOST", "--host=HOST", type: String, desc: "Change host if running a public node (default localhost)"
      option "-p NUMBER", "--port=NUMBER", type: UInt32, desc: "Change port (default 3001)"
      option "-x NUMBER", "--max-connections=NUMBER", type: UInt16, desc: "Change max-connections (default 5)"
      option "-M", "--miner", type: Bool, desc: "Start as miner (default false)"
      option "-a", "--address=ADDRESS", type: String, desc: "Required for the block reward if started as miner"
      option "-m", "--master", type: Bool, desc: "Start as master (default false)"
      run do |opts, _args|
        if opts.miner && !opts.address
          puts "You need to pass an address for the block reward `--address`"
          return
        end
        Node.settings.host = opts.host.as(String) if opts.host
        Node.settings.port = opts.port.as(UInt32) if opts.port
        Node.settings.max_connections = opts.max_connections.as(UInt16) if opts.max_connections
        Node.settings.miner = opts.miner if opts.miner
        Node.settings.miner_address = opts.address.as(String) if opts.address
        Node.settings.master = opts.master if opts.master

        Cocol.logger.info { Node.settings.inspect }

        spawn { Cocol::App::Api.run port: Node.settings.port }
        spawn { Cocol::App::Miner.run } if Node.settings.miner
        Ledger::Pow.genesis
        Messenger.establish_network_position if !Node.settings.master
        spawn { Ledger::Sync.call } if !Node.settings.master

        sleep
      end
    end
  end
end

Cocol::Command.start(ARGV)
