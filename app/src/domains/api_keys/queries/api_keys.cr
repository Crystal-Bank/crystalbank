module CrystalBank::Domains::ApiKeys
  module Queries
    class ApiKeys
      struct ApiKey
        include DB::Serializable
        include DB::Serializable::NonStrict
        include JSON::Serializable

        @[DB::Field(key: "uuid")]
        getter id : UUID
        getter object : String = "api_key"

        getter active : Bool
        getter name : String
        getter user_id : UUID
        getter created_at : Time
        getter revoked_at : Time?
      end

      def initialize
        @db = ES::Config.projection_database
      end

      def list(
        cursor : UUID?,
        limit : Int32,
      ) : Array(ApiKey)
        query_param_counter = 0
        query = [] of String
        query_params = Array(UUID? | Int32).new

        query << %(SELECT * FROM "projections"."api_keys" WHERE 1=1)

        # Add pagination cursor to query
        unless cursor.nil?
          query << %(AND "uuid" >= $#{query_param_counter += 1})
          query_params << cursor
        end

        query << %(ORDER BY "uuid" ASC)
        query << %(LIMIT $#{query_param_counter += 1})
        query_params << limit

        @db.query_all(query.join(" "), args: query_params, as: ApiKey)
      end
    end
  end
end
