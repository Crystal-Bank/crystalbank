module CrystalBank::Domains::Users
  module Reactors
    module RemoveRoles
      class OnRequested < ES::Reactor
        def call(event : Users::RemoveRoles::Events::Requested)
          request_aggregate_id = event.header.aggregate_id

          # Hydrate the request aggregate to get intent
          request = Users::RemoveRolesRequest::Aggregate.new(request_aggregate_id, event_store: @event_store, event_handlers: @event_handlers)
          request.hydrate

          user_id = request.state.user_id.as(UUID)

          # Hydrate the user aggregate to get scope_id
          user = Users::Aggregate.new(user_id, event_store: @event_store, event_handlers: @event_handlers)
          user.hydrate

          scope_id = user.state.scope_id.as(UUID)

          user_name = user.state.name || user.state.email || user_id.to_s
          role_count = request.state.role_ids.size.to_s
          approval_subject = Approvals::ApprovalSubject.new(
            title: "Role Removal",
            summary: "Remove #{role_count} role(s) from #{user_name}",
            fields: [
              Approvals::ApprovalSubject::Field.new("User", user_name),
              Approvals::ApprovalSubject::Field.new("Roles", role_count),
            ] of Approvals::ApprovalSubject::Field
          )

          # Create an approval workflow for this role removal
          Approvals::Creation::Commands::RequestHandler.new(event_store: @event_store, event_handlers: @event_handlers).handle(
            Approvals::Creation::Commands::Request.new(
              aggregate_id: UUID.v7,
              source_aggregate_type: "UserRolesRemoval",
              source_aggregate_id: request_aggregate_id,
              scope_id: scope_id,
              required_approvals: [
                "write_users_remove_roles_approval",
              ],
              actor_id: request.state.requestor_id,
              subject: approval_subject,
            )
          )
        end
      end
    end
  end
end
