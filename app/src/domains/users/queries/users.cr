module CrystalBank::Domains::Users
  module Queries
    class Users
      struct User
        include DB::Serializable
        include DB::Serializable::NonStrict
        include JSON::Serializable

        @[DB::Field(key: "uuid")]
        getter id : UUID
        getter scope_id : UUID
        getter object : String = "user"

        getter name : String
        getter email : String
        getter status : String
      end

      def initialize
        @db = ES::Config.projection_database
      end

      def get(uuid : UUID) : User?
        @db.query_one?("SELECT * FROM projections.users WHERE uuid = $1", args: [uuid], as: User)
      end

      def list(
        context : CrystalBank::Api::Context,
        cursor : UUID?,
        limit : Int32,
      ) : Array(User)
        query_param_counter = 0
        query = [] of String
        query_params = Array(Array(UUID) | UUID? | Int32).new

        query << %(SELECT * FROM "projections"."users" WHERE 1=1)

        # Add scope query
        query << %(AND "scope_id" = ANY($#{query_param_counter += 1}::uuid[]))
        query_params << context.available_scopes

        # Add pagination cursor to query
        unless cursor.nil?
          query << %(AND "uuid" >= $#{query_param_counter += 1})
          query_params << cursor
        end

        query << %(ORDER BY "uuid" ASC)
        query << %(LIMIT $#{query_param_counter += 1})
        query_params << limit

        @db.query_all(query.join(" "), args: query_params, as: User)
      end
    end
  end
end
