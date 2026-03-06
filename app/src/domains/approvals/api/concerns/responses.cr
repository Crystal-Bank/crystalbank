module CrystalBank::Domains::Approvals
  module Api
    module Responses
      struct ApprovalResponse
        include JSON::Serializable

        @[JSON::Field(format: "uuid")]
        getter id : UUID
        @[JSON::Field(format: "uuid")]
        getter reference_aggregate_id : UUID
        getter reference_type : String
        @[JSON::Field(format: "uuid")]
        getter scope_id : UUID
        getter required_approvals : Array(CrystalBank::Objects::Approval)
        getter submitted_steps : Array(CrystalBank::Domains::Approvals::Aggregate::SubmittedStep)
        getter status : String
        getter created_at : Time
        getter updated_at : Time

        def initialize(r : CrystalBank::Domains::Approvals::Queries::Approvals::Approval)
          @id = r.id
          @reference_aggregate_id = r.reference_aggregate_id
          @reference_type = r.reference_type
          @scope_id = r.scope_id
          @required_approvals = r.required_approvals
          @submitted_steps = r.submitted_steps
          @status = r.status
          @created_at = r.created_at
          @updated_at = r.updated_at
        end
      end
    end
  end
end
