module CrystalBank::Domains::Payments::Sepa::CreditTransfers
  module Queries
    class CreditTransfers
      struct CreditTransfer
        include DB::Serializable
        include DB::Serializable::NonStrict
        include JSON::Serializable

        getter uuid : UUID
        getter aggregate_version : Int64
        getter scope_id : UUID
        getter end_to_end_id : String
        getter debtor_account_id : UUID
        getter creditor_iban : String
        getter creditor_name : String
        getter creditor_bic : String?
        getter amount : Int64
        getter currency : String
        getter execution_date : Time
        getter remittance_information : String
        getter status : String
        getter ledger_transaction_id : UUID?
        getter created_at : Time
        getter updated_at : Time
      end

      def initialize
        @db = ES::Config.projection_database
      end

      def list(
        context : CrystalBank::Api::Context,
        cursor : UUID?,
        limit : Int32,
        status : String? = nil,
        scope_id : UUID? = nil,
      ) : Array(CreditTransfer)
        query_param_counter = 0
        query = [] of String
        query_params = Array(Array(UUID) | UUID? | Int32 | String).new

        query << %(SELECT * FROM "projections"."sepa_credit_transfers" WHERE 1=1)

        query << %(AND "scope_id" = ANY($#{query_param_counter += 1}::uuid[]))
        query_params << context.available_scopes

        unless scope_id.nil?
          query << %(AND "scope_id" = $#{query_param_counter += 1})
          query_params << scope_id
        end

        unless status.nil?
          query << %(AND "status" = $#{query_param_counter += 1})
          query_params << status
        end

        unless cursor.nil?
          query << %(AND "uuid" >= $#{query_param_counter += 1})
          query_params << cursor
        end

        query << %(ORDER BY "uuid" ASC)
        query << %(LIMIT $#{query_param_counter += 1})
        query_params << limit

        @db.query_all(query.join(" "), args: query_params, as: CreditTransfer)
      end
    end
  end
end
