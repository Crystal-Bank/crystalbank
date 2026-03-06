module CrystalBank::Domains::Approvals
  module Aggregates
    module Concerns
      module Workflow
        def apply(event : Approvals::Workflow::Events::Initiated)
          @state.increase_version(event.header.aggregate_version)

          body = event.body.as(Approvals::Workflow::Events::Initiated::Body)
          @state.domain_event_handle = body.domain_event_handle
          @state.reference_aggregate_id = body.reference_aggregate_id
          @state.scope_id = body.scope_id
          @state.requester_id = body.requester_id
          @state.approval_permission = body.approval_permission
          @state.required_approvers = body.required_approvers
          @state.status = Approvals::Aggregate::Status::Pending
        end

        def apply(event : Approvals::Decision::Events::Made)
          @state.increase_version(event.header.aggregate_version)

          body = event.body.as(Approvals::Decision::Events::Made::Body)
          @state.decisions << Approvals::Aggregate::Decision.new(
            approver_id: body.approver_id,
            decision: body.decision,
            comment: body.comment
          )
        end

        def apply(event : Approvals::Workflow::Events::Completed)
          @state.increase_version(event.header.aggregate_version)

          body = event.body.as(Approvals::Workflow::Events::Completed::Body)
          @state.status = body.status
        end
      end
    end
  end
end
