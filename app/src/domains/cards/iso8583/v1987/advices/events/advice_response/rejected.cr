module CrystalBank::Domains::Cards::Iso8583::V1987::Advices
  module AdviceResponse
    module Events
      class Rejected < ES::Event
        include ::ES::EventDSL

        define_event "Cards.Iso8583.V1987.Advice", "cards.iso8583.v1987.advices.advice_response.rejected" do
          attribute response_code, String
          attribute reason, String?
        end
      end
    end
  end
end
