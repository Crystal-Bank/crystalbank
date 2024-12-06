module CrystalBank::Domains::ApiKeys
  module Api
    module Responses
      struct ApiKey
        include JSON::Serializable

        @[JSON::Field(format: "uuid", description: "ID of the api-key")]
        getter id : UUID
        @[JSON::Field(description: "Object type of the entity")]
        getter object : String = "api-key"

        @[JSON::Field(format: "iso8601", description: "Timestamp of the creation of the api-key")]
        getter created_at : Time
        @[JSON::Field(description: "Custom name of the api-key")]
        getter name : String

        def initialize(@id, @name, @created_at)
        end
      end

      struct GenerationResponse
        include JSON::Serializable

        @[JSON::Field(format: "uuid", description: "ID of the api-key")]
        getter id : UUID
        @[JSON::Field(description: "Secret of the api-key (only displayed once on creation)")]
        getter secret : String

        def initialize(@id, @secret)
        end
      end
    end
  end
end
