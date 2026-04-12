module CrystalBank::Domains::Scopes
  module Queries
    class ScopesTree
      def initialize
        @db = ES::Config.projection_database
      end

      # Walks up the scope tree from the given UUID, returning the scope itself
      # and all its ancestors up to the root (inclusive). Returns an empty array
      # if the scope does not exist or is not active.
      def parent_scopes(uuid : UUID) : Array(UUID)
        @db.query_all(%(
          WITH RECURSIVE ancestor_scopes (uuid, parent_scope_id) AS (
            SELECT uuid, parent_scope_id
            FROM projections.scopes
            WHERE uuid = $1
              AND status = 'active'
            UNION ALL
            SELECT s.uuid, s.parent_scope_id
            FROM projections.scopes s
            INNER JOIN ancestor_scopes a ON s.uuid = a.parent_scope_id
            WHERE s.uuid <> a.uuid
              AND s.status = 'active'
          )
          SELECT uuid FROM ancestor_scopes
        ), args: [uuid], as: UUID)
      end

      def child_scopes(uuid : UUID) : Array(UUID)
        child_scopes([uuid])
      end

      def child_scopes(uuids : Array(UUID)) : Array(UUID)
        query = [] of String
        query << %(
          WITH RECURSIVE available_scopes (
            uuid
          ) AS (
            SELECT
              uuid
            FROM
              projections.scopes
            WHERE
              uuid IN ($1)
              AND status = 'active'
            UNION ALL
            SELECT
              s.uuid
            FROM
              projections.scopes s,
              available_scopes parent
            WHERE
              s.parent_scope_id = parent.uuid
              AND s.uuid <> s.parent_scope_id
              AND s.status = 'active'
          )
          SELECT
            uuid
          FROM
            available_scopes
        )

        @db.query_all(query.join(" "), args: uuids, as: UUID)
      end
    end
  end
end
