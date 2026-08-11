module CrystalBank::Domains::Roles
  module Reactors
    module Creation
      class OnRequested < ES::Reactor
        def call(event : Roles::Creation::Events::Requested)
          aggregate_id = event.header.aggregate_id

          # Build the role aggregate
          aggregate = Roles::Aggregate.new(aggregate_id, event_store: @event_store, event_handlers: @event_handlers)
          aggregate.hydrate

          scope_id = aggregate.state.scope_id.as(UUID)

          role_name = aggregate.state.name || "unknown"
          scope = Scopes::Queries::Scopes.new.get(scope_id)
          scope_label = scope ? "#{scope.name} (#{scope_id})" : scope_id.to_s
          approval_subject = Approvals::ApprovalSubject.new(
            title: "Role Creation",
            summary: role_name,
            fields: [
              Approvals::ApprovalSubject::Field.new("Name", role_name),
              Approvals::ApprovalSubject::Field.new("Scope", scope_label),
            ] of Approvals::ApprovalSubject::Field
          )

          # Create an approval workflow for this role creation
          Approvals::Creation::Commands::RequestHandler.new(event_store: @event_store, event_handlers: @event_handlers).handle(
            Approvals::Creation::Commands::Request.new(
              aggregate_id: UUID.v7,
              source_aggregate_type: "Role",
              source_aggregate_id: aggregate_id,
              scope_id: scope_id,
              required_approvals: [
                "write_roles_creation_approval",
              ],
              actor_id: aggregate.state.requestor_id,
              subject: approval_subject,
            )
          )
        end
      end
    end
  end
end
