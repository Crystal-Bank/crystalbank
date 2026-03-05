module CrystalBank::Domains::ApiKeys
  module Revocation
    module Events
      class Accepted < ES::Event
        include ::ES::EventDSL

        define_event "ApiKey", "api_key.revocation.accepted"
      end
    end
  end
end
