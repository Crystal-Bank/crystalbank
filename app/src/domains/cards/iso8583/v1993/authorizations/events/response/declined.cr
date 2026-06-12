module CrystalBank::Domains::Cards::Iso8583::V1993::Authorizations
  module Response
    module Events
      class Declined < ES::Event
        include ::ES::EventDSL

        define_event "Cards.Iso8583.V1993.Authorization", "cards.iso8583.v1993.authorizations.response.declined" do
          attribute response_code, String
          attribute reason, String?
        end
      end
    end
  end
end
