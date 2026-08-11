module CrystalBank::Domains::VirtualAccounts
  module Reactors
    module Opening
      class OnApprovalCompleted < ES::Reactor
        def call(event : Approvals::Collection::Events::Completed)
          approval = Approvals::Aggregate.new(event.header.aggregate_id, event_store: @event_store, event_handlers: @event_handlers)
          approval.hydrate

          return unless approval.state.source_aggregate_type == "VirtualAccount"

          virtual_account_id = approval.state.source_aggregate_id.as(UUID)

          VirtualAccounts::Opening::Commands::AcceptHandler.new(event_store: @event_store, event_handlers: @event_handlers).handle(
            VirtualAccounts::Opening::Commands::Accept.new(aggregate_id: virtual_account_id)
          )
        end
      end
    end
  end
end
