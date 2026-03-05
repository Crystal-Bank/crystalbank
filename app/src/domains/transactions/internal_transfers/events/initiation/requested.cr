module CrystalBank::Domains::Transactions::InternalTransfers
  module Initiation
    module Events
      class Requested < ES::Event
        include ::ES::EventDSL

        define_event "Transaction", "transactions.internal_transfer.initiation.requested" do
          attribute currency, CrystalBank::Types::Currencies::Supported
          attribute amount, Int64
          attribute creditor_account_id, UUID
          attribute debtor_account_id, UUID
          attribute remittance_information, String
          attribute scope_id, UUID
        end
      end
    end
  end
end
