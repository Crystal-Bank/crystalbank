module CrystalBank::Domains::Users
  module Reactors
    module RemoveRoles
      class OnApprovalCompleted < ES::Reactor
        def call(event : Approvals::Collection::Events::Completed)
          approval = Approvals::Aggregate.new(event.header.aggregate_id, event_store: @event_store, event_handlers: @event_handlers)
          approval.hydrate

          # Only process if this approval is for a UserRolesRemoval request
          return unless approval.state.source_aggregate_type == "UserRolesRemoval"

          request_id = approval.state.source_aggregate_id.as(UUID)

          Users::RemoveRoles::Commands::AcceptHandler.new(event_store: @event_store, event_handlers: @event_handlers).handle(
            Users::RemoveRoles::Commands::Accept.new(aggregate_id: request_id, requestor_id: approval.state.requestor_id)
          )
        end
      end
    end
  end
end
