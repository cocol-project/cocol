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

  module Command
    module Base
      protected def run(options)
        Node.settings.host = options.string["host"] if options.string["host"]?
        Node.settings.port = options.int["port"].to_u32 if options.int["port"]?
        Node.settings.max_connections = options.int["max_connections"].to_u16 if options.int["max_connections"]?
        Node.settings.miner = options.bool["miner"] if options.bool["miner"]?
        Node.settings.master = options.bool["master"] if options.bool["master"]?

        Cocol.logger.info Node.settings.inspect

        spawn { Cocol::App::Api.run port: Node.settings.port }
        spawn { Cocol::App::Miner.run }
        Ledger::Pow.genesis
        Messenger.establish_network_position if !Node.settings.master

        sleep
      end
    end

    module Local
      extend self
      include Base

      def call(options)
        run(options)
      end
    end

    module Public
      extend self
      include Base

      def call(options)
        if options.string["host"]?.presence.nil?
          puts "When connecting to a public network you have to provide your host address"
          return
        end

        run(options)
      end
    end
  end
end

cli = Commander::Command.new do |client|
  client.use = "cocol"
  client.long = "Cocol Client - mininal blockchain testbed"

  client.commands.add do |pub|
    pub.use = "public"
    pub.short = "Connect to a public network"
    pub.long = pub.short

    pub.flags.add do |flag|
      flag.name = "host"
      flag.description = "Needed for public network"
      flag.long = "--host"
      flag.short = "-h"
      flag.default = ""
    end

    pub.flags.add do |flag|
      flag.name = "port"
      flag.description = "Your pub's API port"
      flag.long = "--port"
      flag.short = "-p"
      flag.default = 3001
    end

    pub.flags.add do |flag|
      flag.name = "max-connection"
      flag.description = "Max connections allowed to other nodes"
      flag.long = "--max-connections"
      flag.short = "-x"
      flag.default = 5
    end

    pub.flags.add do |flag|
      flag.name = "miner"
      flag.description = "Passing this will make your client a miner"
      flag.long = "--miner"
      flag.short = "-M"
      flag.default = false
    end

    pub.flags.add do |flag|
      flag.name = "master"
      flag.description = "Is your node a master node?"
      flag.long = "--master"
      flag.short = "-m"
      flag.default = false
    end

    pub.run do |options, _arguments|
      Cocol::Command::Public.call(options)
    end
  end

  client.flags.add do |flag|
    flag.name = "port"
    flag.description = "Your client's API port"
    flag.long = "--port"
    flag.short = "-p"
    flag.default = 3001
  end

  client.flags.add do |flag|
    flag.name = "max-connection"
    flag.description = "Max connections allowed to other nodes"
    flag.long = "--max-connections"
    flag.short = "-x"
    flag.default = 5
  end

  client.flags.add do |flag|
    flag.name = "miner"
    flag.description = "Passing this will make your client a miner"
    flag.long = "--miner"
    flag.short = "-M"
    flag.default = false
  end

  client.flags.add do |flag|
    flag.name = "master"
    flag.description = "Is your node a master node?"
    flag.long = "--master"
    flag.short = "-m"
    flag.default = false
  end

  client.run do |options, _arguments|
    Cocol::Command::Local.call(options)
  end
end

Commander.run(cli, ARGV)
