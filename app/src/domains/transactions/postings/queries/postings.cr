module CrystalBank::Domains::Transactions::Postings
  module Queries
    class Postings
      struct Posting
        include DB::Serializable
        include DB::Serializable::NonStrict
        include JSON::Serializable

        @[DB::Field(key: "uuid")]
        getter id : UUID
        getter object : String = "posting"

        getter account_id : UUID
        getter amount : Int64
        getter creditor_account_id : UUID
        getter currency : CrystalBank::Types::Currencies::Available
        getter debtor_account_id : UUID
        getter remittance_information : String
      end

      def initialize
        @db = ES::Config.projection_database
      end

      def list(
        cursor : UUID?,
        limit : Int32,
      ) : Array(Posting)
        query_param_counter = 0

        query = [] of String
        query_params = Array(UUID? | Int32).new

        query << %(SELECT * FROM "projections"."postings" WHERE 1=1)

        # Add pagination cursor to query
        unless cursor.nil?
          query << %(AND "uuid" >= $#{query_param_counter += 1})
          query_params << cursor
        end

        query << %(ORDER BY "uuid" ASC)
        query << %(LIMIT $#{query_param_counter += 1})
        query_params << limit

        @db.query_all(query.join(" "), args: query_params, as: Posting)
      end
    end
  end
end
