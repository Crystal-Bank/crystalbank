module CrystalBank::Domains::Platform
  module Api
    module TypeResponses
      struct TypesResponse
        include JSON::Serializable

        @[JSON::Field(description: "Sorted list of type values")]
        getter values : Array(String)

        def initialize(@values : Array(String))
        end
      end

      struct PermissionGroupsResponse
        include JSON::Serializable

        @[JSON::Field(description: "Permission groups with descriptions and per-permission metadata")]
        getter groups : Array(Queries::PermissionGroups::GroupEntry)

        def initialize(@groups : Array(Queries::PermissionGroups::GroupEntry))
        end
      end
    end
  end
end
