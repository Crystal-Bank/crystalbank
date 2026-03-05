module CrystalBank::Domains::ApiKeys
  module Generation
    module Events
      class Accepted < ES::Event
        include ::ES::EventDSL

        define_event "ApiKey", "api_key.generation.accepted"
      end
    end
  end
end
