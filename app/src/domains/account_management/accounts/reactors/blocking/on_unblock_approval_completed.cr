module CrystalBank::Domains::Accounts
  module Reactors
    module Blocking
      class OnUnblockApprovalCompleted < ES::Reactor
        def call(event : Approvals::Collection::Events::Completed)
          approval = Approvals::Aggregate.new(event.header.aggregate_id, event_store: @event_store, event_handlers: @event_handlers)
          approval.hydrate

          return unless approval.state.source_aggregate_type == "AccountUnblock"

          unblock_request_id = approval.state.source_aggregate_id.as(UUID)

          Accounts::Blocking::Commands::RemoveHandler.new(event_store: @event_store, event_handlers: @event_handlers).handle(
            Accounts::Blocking::Commands::Remove.new(aggregate_id: unblock_request_id, requestor_id: approval.state.requestor_id)
          )
        end
      end
    end
  end
end
