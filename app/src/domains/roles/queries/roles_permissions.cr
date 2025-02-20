module CrystalBank::Domains::Roles
  module Queries
    class RolesPermissions
      struct RoleScopes
        include DB::Serializable
        include DB::Serializable::NonStrict

        @[DB::Field(key: "scopes", converter: CrystalBank::Converters::UUIDArray)]
        getter scope_ids : Array(UUID)
      end

      def initialize
        @db = ES::Config.projection_database
      end

      def available_scopes(roles : Array(UUID), permission : CrystalBank::Permissions) : Array(UUID)
        CrystalBank.print_verbose("Roles provided", roles)
        scopes = [] of UUID

        query = [] of String
        query << %(
          SELECT
            scopes
          FROM
            projections.roles
          WHERE
            uuid IN ($1)
            AND $2 = ANY(SELECT jsonb_array_elements_text(permissions))
        )
        rs = @db.query_all(query.join(" "), args: [roles, permission.to_s], as: RoleScopes)
        rs.each { |r| scopes.concat(r.scope_ids) }
        scopes.uniq
      end
    end
  end
end
