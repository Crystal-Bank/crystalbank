module CrystalBank::Domains::Roles
  module Api
    module Requests
      struct CreationRequest
        include JSON::Serializable

        getter name : String
        getter permissions : Array(CrystalBank::Permissions)
        getter scopes : Array(UUID)
      end
    end
  end
end
