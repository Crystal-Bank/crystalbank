module CrystalBank::Domains::Payments::Sepa::CreditTransfers
  module Initiation
    module Events
      class Requested < ES::Event
        include ::ES::EventDSL

        define_event "Payments.Sepa.CreditTransfer", "payments.sepa.credit_transfers.initiation.requested" do
          attribute end_to_end_id, String
          attribute debtor_account_id, UUID
          attribute settlement_account_id, UUID
          attribute creditor_iban, String
          attribute creditor_name, String
          attribute creditor_bic, String?
          attribute amount, Int64
          attribute execution_date, Time
          attribute remittance_information, String
          attribute scope_id, UUID
        end
      end
    end
  end
end
