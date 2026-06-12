module CrystalBank::Domains::Cards::Iso8583::V1993::Authorizations
  module Request
    module Events
      class Received < ES::Event
        include ::ES::EventDSL

        define_event "Cards.Iso8583.V1993.Authorization", "cards.iso8583.v1993.authorizations.request.received" do
          attribute stan, String
          attribute pan_masked, String
          attribute amount, Int64
          attribute currency, String
          attribute terminal_id, String
          attribute merchant_id, String
          attribute account_id_1, String?
          attribute account_id_2, String?
          attribute scope_id, UUID
          attribute raw_mti, String
        end
      end
    end
  end
end
