require "optarg"

class CLI::Argument < Optarg::Model
  arg "command"
  string %w(-p --port)
  bool %w(-m --master)
  string %w(--max-connections)
  bool %w(--miner)
  bool %w(--update)
end
