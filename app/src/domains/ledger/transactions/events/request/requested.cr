module CrystalBank::Domains::Ledger::Transactions
  module Request
    module Events
      class Requested < ES::Event
        include ::ES::EventDSL

        define_event "LedgerTransaction", "ledger.transactions.request.requested" do
          attribute currency, String
          attribute entries_json, String
          attribute posting_date, String?
          attribute value_date, String?
          attribute remittance_information, String
          attribute payment_type, String?
          attribute external_ref, String?
          attribute channel, String?
          attribute internal_note, String?
          attribute scope_id, UUID
        end
      end
    end
  end
end
