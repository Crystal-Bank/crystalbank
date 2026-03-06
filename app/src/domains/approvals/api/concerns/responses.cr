module CrystalBank::Domains::Approvals
  module Api
    module Responses
      struct ApprovalResponse
        include JSON::Serializable

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

        def initialize(
          @id : UUID,
          @domain_event_handle : String,
          @reference_aggregate_id : UUID,
          @scope_id : UUID,
          @requester_id : UUID,
          @approval_permission : String,
          @required_approvers : Int32,
          @approval_count : Int32,
          @status : String
        ); end
      end
    end
  end
end
