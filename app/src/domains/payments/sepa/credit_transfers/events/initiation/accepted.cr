module CrystalBank::Domains::Payments::Sepa::CreditTransfers
  module Initiation
    module Events
      class Accepted < ES::Event
        include ::ES::EventDSL

        define_event "Payments.Sepa.CreditTransfer", "payments.sepa.credit_transfers.initiation.accepted" do
          attribute ledger_transaction_id, UUID
        end
      end
    end
  end
end
