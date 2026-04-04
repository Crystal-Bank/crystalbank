module CrystalBank::Domains::Customers
  module Queries
    class Customers
      struct Customer
        include DB::Serializable
        include DB::Serializable::NonStrict
        include JSON::Serializable

        @[DB::Field(key: "uuid")]
        getter id : UUID
        getter scope_id : UUID
        getter object : String = "customer"

        getter name : String
        getter type : String
      end

      def initialize
        @db = ES::Config.projection_database
      end

      def find_all(uuids : Array(UUID), scope_id : UUID? = nil) : Array(Customer)
        return Array(Customer).new if uuids.empty?
        if scope_id
          @db.query_all(
            %(SELECT * FROM "projections"."customers" WHERE "uuid" = ANY($1) AND "scope_id" = $2),
            uuids, scope_id,
            as: Customer
          )
        else
          @db.query_all(
            %(SELECT * FROM "projections"."customers" WHERE "uuid" = ANY($1)),
            uuids,
            as: Customer
          )
        end
      end

      def list(
        context : CrystalBank::Api::Context,
        cursor : UUID?,
        limit : Int32,
      ) : Array(Customer)
        query_param_counter = 0
        query = [] of String
        query_params = Array(Array(UUID) | UUID? | Int32).new

        query << %(SELECT * FROM "projections"."customers" WHERE 1=1)

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

        @db.query_all(query.join(" "), args: query_params, as: Customer)
      end
    end
  end
end
