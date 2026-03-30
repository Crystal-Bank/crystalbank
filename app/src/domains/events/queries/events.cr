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
        getter aggregate_id : UUID
        getter aggregate_type : String
        getter aggregate_version : Int64
        getter event_handle : String
        getter actor_id : UUID?
        getter created_at : Time
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

        query << %(SELECT * FROM "projections"."events" WHERE 1=1)

        query << %(AND "scope_id" = ANY($#{query_param_counter += 1}::uuid[]))
        query_params << context.available_scopes

        unless aggregate_type.nil?
          query << %(AND "aggregate_type" = $#{query_param_counter += 1})
          query_params << aggregate_type
        end

        unless event_handle.nil?
          query << %(AND "event_handle" = $#{query_param_counter += 1})
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
