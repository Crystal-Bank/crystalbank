module CrystalBank::Domains::Ledger::Transactions
  module Queries
    class Postings
      struct Posting
        include DB::Serializable
        include DB::Serializable::NonStrict
        include JSON::Serializable

        getter id : UUID
        getter transaction_id : UUID

        getter account_id : UUID
        getter aggregate_version : Int64
        getter created_at : Time
        getter direction : String
        getter amount : Int64
        getter entry_type : String
        getter currency : String
        getter posting_date : Time
        getter value_date : Time
        getter remittance_information : String
        getter payment_type : String?
        getter external_ref : String?
        getter channel : String?
      end

      def initialize
        @db = ES::Config.projection_database
      end

      def list(
        context : CrystalBank::Api::Context,
        cursor : UUID?,
        limit : Int32,
        account_id : UUID? = nil,
        scope_id : UUID? = nil,
      ) : Array(Posting)
        query_param_counter = 0
        query = [] of String
        query_params = Array(Array(UUID) | UUID? | Int32).new

        query << %(SELECT * FROM "projections"."postings" WHERE 1=1)

        # Add scope query
        query << %(AND "scope_id" = ANY($#{query_param_counter += 1}::uuid[]))
        query_params << context.available_scopes

        unless scope_id.nil?
          query << %(AND "scope_id" = $#{query_param_counter += 1})
          query_params << scope_id
        end

        unless account_id.nil?
          query << %(AND "account_id" = $#{query_param_counter += 1})
          query_params << account_id
        end

        unless cursor.nil?
          query << %(AND "transaction_id" >= $#{query_param_counter += 1})
          query_params << cursor
        end

        query << %(ORDER BY "transaction_id" ASC)
        query << %(LIMIT $#{query_param_counter += 1})
        query_params << limit

        @db.query_all(query.join(" "), args: query_params, as: Posting)
      end
    end
  end
end
