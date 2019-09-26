require "./model/transaction"

module Ledger
  module Mempool
    extend self

    include Ledger::Model

    alias TxnHash = String

    def pending : Hash(TxnHash, Transaction)
      @@pending ||= Hash(TxnHash, Transaction).new
    end

    def remove(arg) : Bool
      case arg
      when TxnHash
        return false if !pending[arg]?

        pending.delete(arg)
        true
      when Array
        arg.each { |txn| self.remove(txn.hash)}
        true
      else
        false
      end
    end

    def add(txn : Transaction) : Bool
      return false if pending[txn.hash]?

      pending[txn.hash] = txn
      true
    end
  end
end
