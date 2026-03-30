module CrystalBank::Domains::Events
  module Queries
    class Events
      struct Event
        include DB::Serializable
        include DB::Serializable::NonStrict
        include JSON::Serializable

        @[DB::Field(key: "event_id")]
        getter id : UUID
        getter scope_id : UUID
        getter header : String
        getter body : String?
      end

      def initialize
        @db = ES::Config.projection_database
      end

      def list(
        context : CrystalBank::Api::Context,
        cursor : UUID?,
        limit : Int32,
        aggregate_type : String? = nil,
        event_handle : String? = nil,
      ) : Array(Event)
        query_param_counter = 0
        query = [] of String
        query_params = Array(Array(UUID) | UUID? | Int32 | String).new

        query << %(SELECT event_id, scope_id, header::text AS header, body::text AS body FROM "projections"."events" WHERE 1=1)

        query << %(AND "scope_id" = ANY($#{query_param_counter += 1}::uuid[]))
        query_params << context.available_scopes

        unless aggregate_type.nil?
          query << %(AND header->>'aggregate_type' = $#{query_param_counter += 1})
          query_params << aggregate_type
        end

        unless event_handle.nil?
          query << %(AND header->>'event_handle' = $#{query_param_counter += 1})
          query_params << event_handle
        end

        unless cursor.nil?
          query << %(AND "event_id" >= $#{query_param_counter += 1})
          query_params << cursor
        end

        query << %(ORDER BY "event_id" ASC)
        query << %(LIMIT $#{query_param_counter += 1})
        query_params << limit

        @db.query_all(query.join(" "), args: query_params, as: Event)
      end
    end
  end
end
