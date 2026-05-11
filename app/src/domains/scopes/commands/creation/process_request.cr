module CrystalBank::Domains::Scopes
  module Creation
    module Commands
      class ProcessRequest < ES::Command
        def call
          aggregate_id = @aggregate_id.as(UUID)

          # Build the scope aggregate
          aggregate = Scopes::Aggregate.new(aggregate_id)
          aggregate.hydrate

          scope_id = aggregate.state.scope_id.as(UUID)

          scope_name = aggregate.state.name || "unknown"
          parent_scope_fields = [] of Approvals::ApprovalSubject::Field
          if (pid = aggregate.state.parent_scope_id)
            parent_name = Scopes::Queries::Scopes.new.get(pid).try(&.name)
            parent_label = parent_name ? "#{parent_name} (#{pid})" : pid.to_s
            parent_scope_fields << Approvals::ApprovalSubject::Field.new("Parent Scope", parent_label)
          end
          approval_subject = Approvals::ApprovalSubject.new(
            title: "Scope Creation",
            summary: scope_name,
            fields: ([
              Approvals::ApprovalSubject::Field.new("Name", scope_name),
            ] of Approvals::ApprovalSubject::Field) + parent_scope_fields
          )

          # Create an approval workflow for this scope creation
          Approvals::Creation::Commands::Request.new.call(
            source_aggregate_type: "Scope",
            source_aggregate_id: aggregate_id,
            scope_id: scope_id,
            required_approvals: [
              "write_scopes_creation_approval",
            ],
            actor_id: aggregate.state.requestor_id,
            subject: approval_subject,
          )
        end
      end
    end
  end
end
