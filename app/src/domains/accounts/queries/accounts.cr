module CrystalBank::Domains::Accounts
  module Queries
    class Accounts
      struct Account
        include DB::Serializable
        include DB::Serializable::NonStrict
        include JSON::Serializable

        @[DB::Field(key: "uuid")]
        getter id : UUID
        getter scope_id : UUID
        getter name : String
        getter object : String = "account"

        @[DB::Field(converter: CrystalBank::Converters::GenericArray(CrystalBank::Types::Currencies::Supported))]
        getter currencies = Array(CrystalBank::Types::Currencies::Supported).new

        @[DB::Field(converter: CrystalBank::Converters::UUIDArray)]
        getter customer_ids = Array(UUID).new

        getter type : String
      end

      def initialize
        @db = ES::Config.projection_database
      end

      def find(uuid : UUID) : Account?
        @db.query_one?(
          %(SELECT * FROM "projections"."accounts" WHERE "uuid" = $1),
          uuid,
          as: Account
        )
      end

      def find_all(uuids : Array(UUID)) : Array(Account)
        return Array(Account).new if uuids.empty?
        @db.query_all(
          %(SELECT * FROM "projections"."accounts" WHERE "uuid" = ANY($1)),
          uuids,
          as: Account
        )
      end

      def list(
        context : CrystalBank::Api::Context,
        cursor : UUID?,
        limit : Int32,
      ) : Array(Account)
        query_param_counter = 0
        query = [] of String
        query_params = Array(Array(UUID) | UUID? | Int32).new

        query << %(SELECT * FROM "projections"."accounts" WHERE 1=1)

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

        puts query_params

        @db.query_all(query.join(" "), args: query_params, as: Account)
      end
    end
  end
end
