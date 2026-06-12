module CrystalBank::Domains::Cards::Iso8583::V1987::Authorizations
  module Response
    module Events
      class Approved < ES::Event
        include ::ES::EventDSL

        define_event "Cards.Iso8583.V1987.Authorization", "cards.iso8583.v1987.authorizations.response.approved" do
          attribute auth_code, String
          attribute response_code, String
        end
      end
    end
  end
end
