module CrystalBank::Domains::Cards::Iso8583::V1993::Advices
  module AdviceResponse
    module Events
      class Accepted < ES::Event
        include ::ES::EventDSL

        define_event "Cards.Iso8583.V1993.Advice", "cards.iso8583.v1993.advices.advice_response.accepted" do
          attribute response_code, String
        end
      end
    end
  end
end
