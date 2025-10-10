module CrystalBank::Domains::Scopes
  module Queries
    class ScopesTree
      def initialize
        @db = ES::Config.projection_database
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
            UNION ALL
            SELECT
              s.uuid
            FROM
              projections.scopes s,
              available_scopes parent
            WHERE
              s.parent_scope_id = parent.uuid
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
