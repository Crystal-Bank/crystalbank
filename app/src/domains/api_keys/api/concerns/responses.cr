module CrystalBank::Domains::ApiKeys
  module Api
    module Responses
      struct ApiKey
        include JSON::Serializable

        @[JSON::Field(format: "uuid", description: "ID of the api-key")]
        getter id : UUID

        @[JSON::Field(description: "Is the api-key active?")]
        getter active : Bool
        @[JSON::Field(format: "iso8601", description: "Timestamp of the generation of the api-key")]
        getter created_at : Time
        @[JSON::Field(description: "Custom name of the api-key")]
        getter name : String
        @[JSON::Field(format: "iso8601", description: "Timestamp of the revocation of the api-key")]
        getter revoked_at : Time?

        def initialize(@id, @active, @name, @created_at, @revoked_at)
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

      struct RevocationResponse
        include JSON::Serializable

        @[JSON::Field(format: "uuid", description: "ID of the api-key")]
        getter id : UUID

        def initialize(@id)
        end
      end
    end
  end
end
