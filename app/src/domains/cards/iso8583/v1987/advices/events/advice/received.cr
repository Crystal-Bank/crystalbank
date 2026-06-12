module CrystalBank::Domains::Cards::Iso8583::V1987::Advices
  module Advice
    module Events
      class Received < ES::Event
        include ::ES::EventDSL

        define_event "Cards.Iso8583.V1987.Advice", "cards.iso8583.v1987.advices.advice.received" do
          attribute stan, String
          attribute pan_masked, String
          attribute amount, Int64
          attribute currency, String
          attribute terminal_id, String
          attribute merchant_id, String
          attribute original_authorization_id, UUID?
          attribute scope_id, UUID
          attribute raw_mti, String
        end
      end
    end
  end
end
