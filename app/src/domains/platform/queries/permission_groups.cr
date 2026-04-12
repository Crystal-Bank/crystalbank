module CrystalBank::Domains::Platform
  module Queries
    class PermissionGroups
      struct PermissionEntry
        include JSON::Serializable

        getter key : String
        getter description : String

        def initialize(permission : CrystalBank::Permissions, meta : CrystalBank::PermissionGroups::PermissionMeta)
          @key = permission.to_s
          @description = meta.description
        end
      end

      struct GroupEntry
        include JSON::Serializable

        getter name : String
        getter description : String
        getter permissions : Array(PermissionEntry)

        def initialize(group : CrystalBank::PermissionGroups::Group)
          @name = group.name
          @description = group.description
          @permissions = group.permissions.map { |p, m| PermissionEntry.new(p, m) }
        end
      end

      def list : Array(GroupEntry)
        CrystalBank::PermissionGroups::GROUPS.map { |g| GroupEntry.new(g) }
      end
    end
  end
end
