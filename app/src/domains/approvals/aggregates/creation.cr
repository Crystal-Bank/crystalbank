module CrystalBank::Domains::Approvals
  module Aggregates
    module Concerns
      module Creation
        def apply(event : Approvals::Creation::Events::Requested)
          @state.increase_version(event.header.aggregate_version)

          body = event.body.as(Approvals::Creation::Events::Requested::Body)
          @state.reference_aggregate_id = body.reference_aggregate_id
          @state.reference_type = body.reference_type
          @state.scope_id = body.scope_id
          @state.required_approvals = body.required_approvals
        end

        def apply(event : Approvals::Creation::Events::Accepted)
          @state.increase_version(event.header.aggregate_version)
        end
      end
    end
  end
end
