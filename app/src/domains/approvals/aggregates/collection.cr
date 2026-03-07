module CrystalBank::Domains::Approvals
  module Aggregates
    module Concerns
      module Collection
        # Apply 'Approvals::Collection::Events::Collected' to the aggregate state
        def apply(event : Approvals::Collection::Events::Collected)
          @state.increase_version(event.header.aggregate_version)

          body = event.body.as(Approvals::Collection::Events::Collected::Body)
          @state.collected_approvals << Approvals::Aggregate::CollectedApproval.new(
            user_id: body.user_id,
            permissions: body.permissions
          )
        end

        # Apply 'Approvals::Collection::Events::Completed' to the aggregate state
        def apply(event : Approvals::Collection::Events::Completed)
          @state.increase_version(event.header.aggregate_version)

          @state.completed = true
        end
      end
    end
  end
end
