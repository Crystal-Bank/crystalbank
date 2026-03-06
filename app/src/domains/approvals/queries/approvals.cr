module CrystalBank::Domains::Approvals
  module Queries
    class Approvals
      struct CollectedApproval
        include DB::Serializable
        include DB::Serializable::NonStrict
        include JSON::Serializable

        getter user_id : UUID
        getter permission : String
      end

      struct Approval
        include DB::Serializable
        include DB::Serializable::NonStrict
        include JSON::Serializable

        @[DB::Field(key: "uuid")]
        getter id : UUID
        getter scope_id : UUID
        getter object : String = "approval"

        getter source_aggregate_type : String
        getter source_aggregate_id : UUID

        @[DB::Field(converter: CrystalBank::Converters::StringArray)]
        getter required_approvals : Array(String)

        @[DB::Field(converter: CrystalBank::Converters::JsonArray(CrystalBank::Domains::Approvals::Queries::Approvals::CollectedApproval))]
        getter collected_approvals : Array(CollectedApproval)

        getter completed : Bool
      end

      def initialize
        @db = ES::Config.projection_database
      end

      def list(
        cursor : UUID?,
        limit : Int32,
      ) : Array(Approval)
        query_param_counter = 0
        query = [] of String
        query_params = Array(UUID? | Int32).new

        query << %(SELECT * FROM "projections"."approvals" WHERE 1=1)

        # Add pagination cursor to query
        unless cursor.nil?
          query << %(AND "uuid" >= $#{query_param_counter += 1})
          query_params << cursor
        end

        query << %(ORDER BY "uuid" ASC)
        query << %(LIMIT $#{query_param_counter += 1})
        query_params << limit

        @db.query_all(query.join(" "), args: query_params, as: Approval)
      end

      def find_by_source(
        source_aggregate_type : String,
        source_aggregate_id : UUID,
      ) : Approval?
        @db.query_one?(
          %(SELECT * FROM "projections"."approvals" WHERE "source_aggregate_type" = $1 AND "source_aggregate_id" = $2 LIMIT 1),
          source_aggregate_type,
          source_aggregate_id,
          as: Approval
        )
      end
    end
  end
end
