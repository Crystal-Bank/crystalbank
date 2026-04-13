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

        @[JSON::Field(description: "Permissions to add to the role")]
        getter permissions_to_add : Array(CrystalBank::Permissions) = [] of CrystalBank::Permissions

        @[JSON::Field(description: "Permissions to remove from the role")]
        getter permissions_to_remove : Array(CrystalBank::Permissions) = [] of CrystalBank::Permissions
      end
    end
  end
end
