module CrystalBank::Domains::Transactions::InternalTransfers
  module Initiation
    module Events
      class Accepted < ES::Event
        include ::ES::EventDSL

        define_event "Transaction", "transactions.internal_transfer.initiation.accepted"
      end
    end
  end
end
