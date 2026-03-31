module CrystalBank::Domains::ApiKeys
  module Revocation
    module Events
      class Requested < ES::Event
        include ::ES::EventDSL

        define_event "ApiKey", "api_key.revocation.requested" do
          attribute :reason, String
          attribute :scope_id, UUID
        end
      end
    end
  end
end
