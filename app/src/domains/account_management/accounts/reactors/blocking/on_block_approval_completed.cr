module CrystalBank::Domains::Accounts
  module Reactors
    module Blocking
      class OnBlockApprovalCompleted < ES::Reactor
        def call(event : Approvals::Collection::Events::Completed)
          approval = Approvals::Aggregate.new(event.header.aggregate_id, event_store: @event_store, event_handlers: @event_handlers)
          approval.hydrate

          return unless approval.state.source_aggregate_type == "AccountBlock"

          block_request_id = approval.state.source_aggregate_id.as(UUID)

          Accounts::Blocking::Commands::ApplyHandler.new(event_store: @event_store, event_handlers: @event_handlers).handle(
            Accounts::Blocking::Commands::Apply.new(aggregate_id: block_request_id, requestor_id: approval.state.requestor_id)
          )
        end
      end
    end
  end
end
