module CrystalBank::Domains::Scopes
  module Reactors
    module NameChange
      class OnApprovalCompleted < ES::Reactor
        def call(event : Approvals::Collection::Events::Completed)
          approval = Approvals::Aggregate.new(event.header.aggregate_id, event_store: @event_store, event_handlers: @event_handlers)
          approval.hydrate

          # Only process if this approval is for a ScopeNameChange
          return unless approval.state.source_aggregate_type == "ScopeNameChange"

          name_change_request_id = approval.state.source_aggregate_id.as(UUID)

          Scopes::NameChange::Commands::AcceptHandler.new(event_store: @event_store, event_handlers: @event_handlers).handle(
            Scopes::NameChange::Commands::Accept.new(aggregate_id: name_change_request_id, requestor_id: approval.state.requestor_id)
          )
        end
      end
    end
  end
end
