module CrystalBank::Domains::Accounts
  module Reactors
    module Closure
      class OnApprovalCompleted < ES::Reactor
        def call(event : Approvals::Collection::Events::Completed)
          approval = Approvals::Aggregate.new(event.header.aggregate_id, event_store: @event_store, event_handlers: @event_handlers)
          approval.hydrate

          return unless approval.state.source_aggregate_type == "AccountClosure"

          closure_request_id = approval.state.source_aggregate_id.as(UUID)

          Accounts::Closure::Commands::AcceptHandler.new(event_store: @event_store, event_handlers: @event_handlers).handle(
            Accounts::Closure::Commands::Accept.new(aggregate_id: closure_request_id)
          )
        end
      end
    end
  end
end
