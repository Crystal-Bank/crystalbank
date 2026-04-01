module CrystalBank::Domains::Scopes
  module Queries
    class Scopes
      struct Scope
        include DB::Serializable
        include DB::Serializable::NonStrict
        include JSON::Serializable

        @[DB::Field(key: "uuid")]
        getter id : UUID
        getter scope_id : UUID
        getter object : String = "scope"

        getter name : String
        getter parent_scope_id : UUID?
      end

      def initialize
        @db = ES::Config.projection_database
      end

      def get(uuid : UUID) : Scope?
        @db.query_one("SELECT * FROM projections.scopes WHERE uuid = $1", args: uuid, as: Scope)
      end

      def list(
        context : CrystalBank::Api::Context,
        cursor : UUID?,
        limit : Int32,
        scope_id : UUID? = nil,
      ) : Array(Scope)
        query_param_counter = 0
        query = [] of String
        query_params = Array(Array(UUID) | UUID? | Int32).new

        query << %(SELECT * FROM "projections"."scopes" WHERE 1=1)

        # Add scope query
        query << %(AND "scope_id" = ANY($#{query_param_counter += 1}::uuid[]))
        query_params << context.available_scopes

        unless scope_id.nil?
          query << %(AND "scope_id" = $#{query_param_counter += 1})
          query_params << scope_id
        end

        # Add pagination cursor to query
        unless cursor.nil?
          query << %(AND "uuid" >= $#{query_param_counter += 1})
          query_params << cursor
        end

        query << %(ORDER BY "uuid" ASC)
        query << %(LIMIT $#{query_param_counter += 1})
        query_params << limit

        @db.query_all(query.join(" "), args: query_params, as: Scope)
      end
    end
  end
end
