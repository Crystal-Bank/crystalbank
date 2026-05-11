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
          approval_subject = Approvals::ApprovalSubject.new(
            title: "Scope Creation",
            summary: scope_name,
            fields: [
              Approvals::ApprovalSubject::Field.new("Name", scope_name),
            ] of Approvals::ApprovalSubject::Field
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
