module CrystalBank::Domains::Users
  module Reactors
    module Onboarding
      class OnApprovalCompleted < ES::Reactor
        def call(event : Approvals::Collection::Events::Completed)
          approval = Approvals::Aggregate.new(event.header.aggregate_id, event_store: @event_store, event_handlers: @event_handlers)
          approval.hydrate

          # Only process if this approval is for a User
          return unless approval.state.source_aggregate_type == "User"

          user_id = approval.state.source_aggregate_id.as(UUID)

          Users::Onboarding::Commands::AcceptHandler.new(event_store: @event_store, event_handlers: @event_handlers).handle(
            Users::Onboarding::Commands::Accept.new(aggregate_id: user_id)
          )
        end
      end
    end
  end
end
