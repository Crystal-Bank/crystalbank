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
        getter status : String
      end

      def initialize
        @db = ES::Config.projection_database
      end

      def find_all(
        context : CrystalBank::Api::Context,
        uuids : Array(UUID), 
        scope_id : UUID? = nil, 
        status : String? = nil
      ) : Array(Customer)
        return Array(Customer).new if uuids.empty?
        query_param_counter = 0
        query = [] of String
        query_params = Array(Array(UUID) | UUID? | String?).new
        
        query << %(SELECT * FROM "projections"."customers" WHERE 1=1)

        query_params << uuids
        conditions = [%(\"uuid\" = ANY($1))]

        # Add scope query
        query << %(AND "scope_id" = ANY($#{query_param_counter += 1}::uuid[]))
        query_params << context.available_scopes

        if scope_id
          query << %(AND "scope_id" = $#{query_param_counter += 1})
          query_params << scope_id
        end
        if status
          query << %(AND "status" = $#{query_param_counter += 1})
          query_params << status
        end

        @db.query_all(query.join(" "), args: query_params, as: Customer)
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
