module CrystalBank::Domains::ApiKeys
  module Generation
    module Events
      class Requested < ES::Event
        include ::ES::EventDSL

        define_event "ApiKey", "api_key.generation.requested" do
          attribute :api_secret, String
          attribute :name, String
          attribute :scope_id, UUID
          attribute :user_id, UUID
        end
      end
    end
  end
end
