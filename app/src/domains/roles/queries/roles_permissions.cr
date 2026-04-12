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

      # Returns the merged, deduplicated, sorted list of permissions for the given
      # roles. When a scope is provided, only roles whose applicable scopes cover
      # that scope (i.e. the scope or any of its ancestors is in the role's scopes
      # list) are included — reflecting that parent-scope permissions trickle down
      # and permissions on independent scope trees do not cross over.
      def all_permissions(roles : Array(UUID), scope : UUID? = nil) : Array(String)
        return [] of String if roles.empty?

        rs = if scope
               ancestor_ids = Scopes::Queries::ScopesTree.new.parent_scopes(scope)
               return [] of String if ancestor_ids.empty?

               @db.query_all(
                 %(
                   SELECT permissions FROM projections.roles
                   WHERE uuid = ANY($1::uuid[])
                     AND EXISTS (
                       SELECT 1 FROM jsonb_array_elements_text(scopes) AS s
                       WHERE s::uuid = ANY($2::uuid[])
                     )
                 ),
                 args: [roles, ancestor_ids],
                 as: RolePerms
               )
             else
               @db.query_all(
                 %(SELECT permissions FROM projections.roles WHERE uuid = ANY($1::uuid[])),
                 args: [roles],
                 as: RolePerms
               )
             end

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
