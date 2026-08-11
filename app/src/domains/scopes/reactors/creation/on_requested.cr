module CrystalBank::Domains::Scopes
  module Reactors
    module Creation
      class OnRequested < ES::Reactor
        def call(event : Scopes::Creation::Events::Requested)
          aggregate_id = event.header.aggregate_id

          # Build the scope aggregate
          aggregate = Scopes::Aggregate.new(aggregate_id, event_store: @event_store, event_handlers: @event_handlers)
          aggregate.hydrate

          scope_id = aggregate.state.scope_id.as(UUID)

          scope_name = aggregate.state.name || "unknown"
          scope_fields = [
            Approvals::ApprovalSubject::Field.new("Name", scope_name),
          ] of Approvals::ApprovalSubject::Field
          if (pid = aggregate.state.parent_scope_id)
            parent_name = Scopes::Queries::Scopes.new.get(pid).try(&.name)
            parent_label = parent_name ? "#{parent_name} (#{pid})" : pid.to_s
            scope_fields << Approvals::ApprovalSubject::Field.new("Parent Scope", parent_label)
          end
          approval_subject = Approvals::ApprovalSubject.new(
            title: "Scope Creation",
            summary: scope_name,
            fields: scope_fields
          )

          # Create an approval workflow for this scope creation
          Approvals::Creation::Commands::RequestHandler.new(event_store: @event_store, event_handlers: @event_handlers).handle(
            Approvals::Creation::Commands::Request.new(
              aggregate_id: UUID.v7,
              source_aggregate_type: "Scope",
              source_aggregate_id: aggregate_id,
              scope_id: scope_id,
              required_approvals: [
                "write_scopes_creation_approval",
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
