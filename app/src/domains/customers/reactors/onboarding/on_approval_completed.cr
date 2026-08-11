module CrystalBank::Domains::Customers
  module Reactors
    module Onboarding
      class OnApprovalCompleted < ES::Reactor
        def call(event : Approvals::Collection::Events::Completed)
          # Hydrate the approval aggregate to get source info
          approval = Approvals::Aggregate.new(event.header.aggregate_id, event_store: @event_store, event_handlers: @event_handlers)
          approval.hydrate

          # Only process if this approval is for a Customer
          return unless approval.state.source_aggregate_type == "Customer"

          customer_id = approval.state.source_aggregate_id.as(UUID)

          Customers::Onboarding::Commands::AcceptHandler.new(event_store: @event_store, event_handlers: @event_handlers).handle(
            Customers::Onboarding::Commands::Accept.new(aggregate_id: customer_id)
          )
        end
      end
    end
  end
end
