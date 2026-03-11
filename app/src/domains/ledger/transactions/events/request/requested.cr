module CrystalBank::Domains::Ledger::Transactions
  module Request
    module Events
      class Requested < ES::Event
        include ::ES::EventDSL

        define_event "LedgerTransaction", "ledger.transactions.request.requested" do
          attribute channel, String?
          attribute currency, CrystalBank::Types::Currencies::Supported
          attribute entries_json, String
          attribute external_ref, String?
          attribute payment_type, String?
          attribute posting_date, String
          attribute remittance_information, String
          attribute scope_id, UUID
          attribute value_date, String
        end
      end
    end
  end
end
