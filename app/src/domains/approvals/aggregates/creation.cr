module CrystalBank::Domains::Approvals
  module Aggregates
    module Concerns
      module Creation
        # Apply 'Approvals::Creation::Events::Requested' to the aggregate state
        def apply(event : Approvals::Creation::Events::Requested)
          @state.increase_version(event.header.aggregate_version)

          body = event.body.as(Approvals::Creation::Events::Requested::Body)
          @state.scope_id = body.scope_id
          @state.source_aggregate_type = body.source_aggregate_type
          @state.source_aggregate_id = body.source_aggregate_id
          @state.required_approvals = body.required_approvals
          @state.requestor_id = event.header.actor_id
        end
      end
    end
  end
end
