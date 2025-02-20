module CrystalBank::Domains::Roles
  module Queries
    class Roles
      struct Role
        include DB::Serializable
        include DB::Serializable::NonStrict
        include JSON::Serializable

        @[DB::Field(key: "uuid")]
        getter id : UUID
        getter object : String = "role"

        getter name : String
        @[DB::Field(converter: CrystalBank::Converters::GenericArray(CrystalBank::Permissions))]
        getter permissions : Array(CrystalBank::Permissions)
        getter scopes : Array(UUID)
      end

      def initialize
        @db = ES::Config.projection_database
      end

      def list(
        cursor : UUID?,
        limit : Int32,
      ) : Array(Role)
        query_param_counter = 0
        query = [] of String
        query_params = Array(UUID? | Int32).new

        query << %(SELECT * FROM "projections"."roles" WHERE 1=1)

        # Add pagination cursor to query
        unless cursor.nil?
          query << %(AND "uuid" >= $#{query_param_counter += 1})
          query_params << cursor
        end

        query << %(ORDER BY "uuid" ASC)
        query << %(LIMIT $#{query_param_counter += 1})
        query_params << limit

        @db.query_all(query.join(" "), args: query_params, as: Role)
      end
    end
  end
end
