module CrystalBank::Domains::Roles
  module Api
    module Requests
      struct CreationRequest
        include JSON::Serializable

        getter name : String
        getter permissions : Array(CrystalBank::Permissions)
        getter scopes : Array(UUID)
      end

      struct PermissionsUpdateRequest
        include JSON::Serializable

        @[JSON::Field(format: "uuid", description: "ID of the role whose permissions should be updated")]
        getter role_id : UUID

        @[JSON::Field(description: "Complete new set of permissions for the role")]
        getter permissions : Array(CrystalBank::Permissions)
      end
    end
  end
end
