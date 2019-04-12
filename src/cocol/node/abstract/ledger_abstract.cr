abstract class LedgerAbstract
  abstract def start
end

abstract class LedgerRepoAbstract
  abstract def pending_transactions
end
