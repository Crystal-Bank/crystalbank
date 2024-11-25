module CrystalBank::Domains::Accounts
  module Queries
    class Accounts
      struct Account
        include DB::Serializable
        include DB::Serializable::NonStrict
        include JSON::Serializable

        @[DB::Field(key: "uuid")]
        getter id : UUID
        getter object : String = "account"

        @[DB::Field(converter: CrystalBank::Converters::CurrencyArray(CrystalBank::Types::Currencies::Supported))]
        getter currencies = Array(CrystalBank::Types::Currencies::Supported).new

        getter type : String
      end

      def initialize
        @db = ES::Config.projection_database
      end

      def list(
        cursor : UUID?, 
        limit : Int32
      ) : Array(Account)
        query = [] of String
        query_params = Array(UUID? | Int32).new

        query << %(SELECT * FROM "projections"."accounts" WHERE 1=1)
  
        # Add pagination cursor to query
        unless cursor.nil?
          query << %(AND "uuid" >= $1) 
          query_params << cursor
        end

        query << %(ORDER BY "uuid" ASC)
        query << %(LIMIT $2)
        query_params << limit

        @db.query_all(query.join(" "), args: query_params, as: Account)
      end
    end
  end
end
