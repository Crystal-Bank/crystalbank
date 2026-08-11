module CrystalBank::Domains::Accounts
  module Reactors
    module Opening
      class OnApprovalCompleted < ES::Reactor
        def call(event : Approvals::Collection::Events::Completed)
          # Hydrate the approval aggregate to get source info
          approval = Approvals::Aggregate.new(event.header.aggregate_id, event_store: @event_store, event_handlers: @event_handlers)
          approval.hydrate

          # Only process if this approval is for an Account
          return unless approval.state.source_aggregate_type == "Account"

          account_id = approval.state.source_aggregate_id.as(UUID)

          Accounts::Opening::Commands::AcceptHandler.new(event_store: @event_store, event_handlers: @event_handlers).handle(
            Accounts::Opening::Commands::Accept.new(aggregate_id: account_id)
          )
        end
      end
    end
  end
end
