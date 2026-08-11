module CrystalBank::Domains::Scopes
  module Reactors
    module Creation
      class OnApprovalCompleted < ES::Reactor
        def call(event : Approvals::Collection::Events::Completed)
          approval = Approvals::Aggregate.new(event.header.aggregate_id, event_store: @event_store, event_handlers: @event_handlers)
          approval.hydrate

          # Only process if this approval is for a Scope
          return unless approval.state.source_aggregate_type == "Scope"

          scope_id = approval.state.source_aggregate_id.as(UUID)

          Scopes::Creation::Commands::AcceptHandler.new(event_store: @event_store, event_handlers: @event_handlers).handle(
            Scopes::Creation::Commands::Accept.new(aggregate_id: scope_id)
          )
        end
      end
    end
  end
end
