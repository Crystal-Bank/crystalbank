module CrystalBank::Domains::Approvals
  module Queries
    class Approvals
      struct Approval
        include DB::Serializable
        include DB::Serializable::NonStrict
        include JSON::Serializable

        @[DB::Field(key: "uuid")]
        getter id : UUID
        getter object : String = "approval"
        getter domain_event_handle : String
        getter reference_aggregate_id : UUID
        getter scope_id : UUID
        getter requester_id : UUID
        getter approval_permission : String
        getter required_approvers : Int32
        getter approval_count : Int32
        getter status : String
        getter created_at : Time
        getter updated_at : Time
      end

      def initialize
        @db = ES::Config.projection_database
      end

      def find(id : UUID) : Approval?
        @db.query_one?(%(SELECT * FROM "projections"."approvals" WHERE uuid = $1), id, as: Approval)
      end

      def list(
        cursor : UUID?,
        limit : Int32,
        status : String? = nil,
      ) : Array(Approval)
        query_param_counter = 0
        query = [] of String
        query_params = Array(UUID? | Int32 | String).new

        query << %(SELECT * FROM "projections"."approvals" WHERE 1=1)

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

        @db.query_all(query.join(" "), args: query_params, as: Approval)
      end
    end
  end
end
