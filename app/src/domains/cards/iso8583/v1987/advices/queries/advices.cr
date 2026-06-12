module CrystalBank::Domains::Cards::Iso8583::V1987::Advices
  module Queries
    class Advices
      struct AdviceResult
        include DB::Serializable
        include JSON::Serializable

        property uuid : UUID
        property stan : String
        property pan_masked : String
        property amount : Int64
        property currency : String
        property terminal_id : String
        property merchant_id : String
        property original_authorization_id : UUID?
        property scope_id : UUID
        property response_code : String?
        property status : String
        property created_at : Time
        property updated_at : Time
      end

      def get(id : UUID, context : CrystalBank::Api::Context) : AdviceResult?
        @db.query_one?(
          "SELECT * FROM projections.iso8583_v1987_advices WHERE uuid = $1 AND scope_id = ANY($2)",
          id, context.available_scopes,
          as: AdviceResult,
        )
      end

      def list(context : CrystalBank::Api::Context, cursor : Int32 = 0, limit : Int32 = 50) : Array(AdviceResult)
        @db.query_all(
          "SELECT * FROM projections.iso8583_v1987_advices WHERE scope_id = ANY($1) ORDER BY created_at DESC LIMIT $2 OFFSET $3",
          context.available_scopes, limit, cursor,
          as: AdviceResult,
        )
      end
    end
  end
end
