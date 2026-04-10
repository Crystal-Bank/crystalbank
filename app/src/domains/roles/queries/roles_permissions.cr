module CrystalBank::Domains::Roles
  module Queries
    class RolesPermissions
      struct RoleScopes
        include DB::Serializable
        include DB::Serializable::NonStrict

        @[DB::Field(key: "scopes", converter: CrystalBank::Converters::UUIDArray)]
        getter scope_ids : Array(UUID)
      end

      struct RolePerms
        include DB::Serializable
        include DB::Serializable::NonStrict

        @[DB::Field(converter: CrystalBank::Converters::GenericArray(CrystalBank::Permissions))]
        getter permissions : Array(CrystalBank::Permissions)
      end

      def initialize
        @db = ES::Config.projection_database
      end

      def all_permissions(roles : Array(UUID)) : Array(String)
        return [] of String if roles.empty?

        rs = @db.query_all(
          %(SELECT permissions FROM projections.roles WHERE uuid = ANY($1::uuid[])),
          args: [roles],
          as: RolePerms
        )

        rs.flat_map(&.permissions).uniq.map(&.to_s).sort
      end

      def available_scopes(roles : Array(UUID), permission : CrystalBank::Permissions) : Array(UUID)
        scopes = [] of UUID

        query = [] of String
        query << %(
        SELECT
            scopes
          FROM
            projections.roles
          WHERE
            uuid = ANY($1::uuid[])
            AND permissions ? $2
        )

        rs = @db.query_all(query.join, args: [roles, permission.to_s], as: RoleScopes)
        rs.each { |r| scopes.concat(r.scope_ids) }
        scopes.uniq
      end
    end
  end
end
