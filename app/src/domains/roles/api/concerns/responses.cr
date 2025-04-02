module CrystalBank::Domains::Roles
  module Api
    module Responses
      # Response to an role creation request
      struct CreationResponse
        include JSON::Serializable

        @[JSON::Field(format: "uuid", description: "ID of the requested role")]
        getter id : UUID

        def initialize(@id : UUID); end
      end

      # Respond with a single role entity
      struct Role
        include JSON::Serializable

        @[JSON::Field(format: "uuid", description: "ID of the requested role")]
        getter id : UUID

        @[JSON::Field(format: "uuid", description: "Scope of the data point")]
        getter scope_id : UUID

        @[JSON::Field(description: "Name of the role")]
        getter name : String

        @[JSON::Field(description: "Permissions of the role")]
        getter permissions : Array(Permissions)

        @[JSON::Field(description: "Scope the role has access to")]
        getter scopes : Array(UUID)

        def initialize(
          @id : UUID,
          @scope_id : UUID,
          @name : String,
          @permissions : Array(CrystalBank::Permissions),
          @scopes : Array(UUID),
        ); end
      end
    end
  end
end
