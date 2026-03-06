module CrystalBank::Domains::Approvals
  module Queries
    class Approvals
      struct Approval
        include DB::Serializable
        include DB::Serializable::NonStrict
        include JSON::Serializable

        @[DB::Field(key: "uuid")]
        getter id : UUID
        getter reference_aggregate_id : UUID
        getter reference_type : String
        getter scope_id : UUID
        getter object : String = "approval"

        @[DB::Field(converter: CrystalBank::Converters::JsonObjectArray(CrystalBank::Objects::Approval))]
        getter required_approvals : Array(CrystalBank::Objects::Approval)

        @[DB::Field(converter: CrystalBank::Converters::JsonObjectArray(CrystalBank::Domains::Approvals::Aggregate::SubmittedStep))]
        getter submitted_steps : Array(CrystalBank::Domains::Approvals::Aggregate::SubmittedStep)

        getter status : String
        getter created_at : Time
        getter updated_at : Time
      end

      def initialize
        @db = ES::Config.projection_database
      end

      def find(id : UUID) : Approval?
        @db.query_one?(
          %(SELECT * FROM "projections"."approvals" WHERE uuid = $1),
          id,
          as: Approval
        )
      end

      def list(
        cursor : UUID?,
        limit : Int32,
        status : String? = nil,
        scope_ids : Array(UUID)? = nil,
        reference_aggregate_id : UUID? = nil
      ) : Array(Approval)
        query_param_counter = 0
        query = [%(SELECT * FROM "projections"."approvals" WHERE 1=1)]
        query_params = Array(DB::Any).new

        unless cursor.nil?
          query << %(AND "uuid" >= $#{query_param_counter += 1})
          query_params << cursor
        end

        unless status.nil?
          query << %(AND "status" = $#{query_param_counter += 1})
          query_params << status
        end

        unless scope_ids.nil? || scope_ids.empty?
          placeholders = scope_ids.map { query_param_counter += 1; "$#{query_param_counter}" }.join(", ")
          query << %(AND "scope_id" IN (#{placeholders}))
          scope_ids.each { |s| query_params << s }
        end

        unless reference_aggregate_id.nil?
          query << %(AND "reference_aggregate_id" = $#{query_param_counter += 1})
          query_params << reference_aggregate_id
        end

        query << %(ORDER BY "uuid" ASC)
        query << %(LIMIT $#{query_param_counter += 1})
        query_params << limit

        @db.query_all(query.join(" "), args: query_params, as: Approval)
      end
    end
  end
end
