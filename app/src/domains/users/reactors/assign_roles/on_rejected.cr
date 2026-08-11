module CrystalBank::Domains::Users
  module Reactors
    module AssignRoles
      class OnRejected < ES::Reactor
        def call(event : Approvals::Rejection::Events::Rejected)
          approval = Approvals::Aggregate.new(event.header.aggregate_id, event_store: @event_store, event_handlers: @event_handlers)
          approval.hydrate

          return unless approval.state.source_aggregate_type == "UserRolesAssignment"

          request_id = approval.state.source_aggregate_id.as(UUID)

          Users::AssignRoles::Commands::RejectHandler.new(event_store: @event_store, event_handlers: @event_handlers).handle(
            Users::AssignRoles::Commands::Reject.new(aggregate_id: request_id)
          )
        end
      end
    end
  end
end
