module CrystalBank::Domains::Roles
  module Api
    module Responses
      # Response to a role permissions update request
      struct PermissionsUpdateResponse
        include JSON::Serializable

        @[JSON::Field(format: "uuid", description: "ID of the permissions update request")]
        getter id : UUID

        def initialize(@id : UUID); end
      end

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

        @[JSON::Field(format: "uuid", description: "ID of the role")]
        getter id : UUID

        @[JSON::Field(format: "uuid", description: "Scope of the data point")]
        getter scope_id : UUID

        @[JSON::Field(description: "Object type: 'role' when accepted, 'role_creation_request' when pending approval")]
        getter object : String

        @[JSON::Field(description: "Name of the role")]
        getter name : String

        @[JSON::Field(description: "Permissions of the role")]
        getter permissions : Array(Permissions)

        @[JSON::Field(description: "Scope the role has access to")]
        getter scopes : Array(UUID)

        @[JSON::Field(description: "Status of the role: active, pending_approval")]
        getter status : String

        def initialize(
          @id : UUID,
          @scope_id : UUID,
          @object : String,
          @name : String,
          @permissions : Array(CrystalBank::Permissions),
          @scopes : Array(UUID),
          @status : String,
        ); end
      end
    end
  end
end
