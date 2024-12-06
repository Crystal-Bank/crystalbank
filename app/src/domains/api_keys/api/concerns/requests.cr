module CrystalBank::Domains::ApiKeys
  module Api
    module Requests
      struct GenerationRequest
        include JSON::Serializable

        @[JSON::Field(description: "Custom name of the api-key")]
        getter name : String

        @[JSON::Field(description: "User id the api-key should be associated with")]
        getter user_id : UUID
      end
    end
  end
end
