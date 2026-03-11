module CrystalBank::Domains::Ledger::Transactions
  module Request
    module Events
      class Accepted < ES::Event
        include ::ES::EventDSL

        define_event "LedgerTransaction", "ledger.transactions.request.accepted"
      end
    end
  end
end
