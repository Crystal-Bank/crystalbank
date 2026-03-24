module CrystalBank::Domains::Approvals
  module Aggregates
    module Concerns
      module Rejection
        # Apply 'Approvals::Rejection::Events::Rejected' to the aggregate state
        def apply(event : Approvals::Rejection::Events::Rejected)
          @state.increase_version(event.header.aggregate_version)

          @state.rejected = true
        end
      end
    end
  end
end
