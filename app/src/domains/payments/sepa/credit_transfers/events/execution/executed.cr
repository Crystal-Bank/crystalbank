module CrystalBank::Domains::Payments::Sepa::CreditTransfers
  module Execution
    module Events
      class Executed < ES::Event
        include ::ES::EventDSL

        define_event "Payments.Sepa.CreditTransfer", "payments.sepa.credit_transfers.execution.executed" do
          attribute ledger_transaction_id, UUID
        end
      end
    end
  end
end
