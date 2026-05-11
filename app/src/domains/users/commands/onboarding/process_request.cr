module CrystalBank::Domains::Users
  module Onboarding
    module Commands
      class ProcessRequest < ES::Command
        def call
          aggregate_id = @aggregate_id.as(UUID)

          # Build the user aggregate
          aggregate = Users::Aggregate.new(aggregate_id)
          aggregate.hydrate

          scope_id = aggregate.state.scope_id.as(UUID)

          name = aggregate.state.name || "unknown"
          email = aggregate.state.email || "unknown"
          approval_subject = Approvals::ApprovalSubject.new(
            title: "User Onboarding",
            summary: "#{name} <#{email}>",
            fields: [
              Approvals::ApprovalSubject::Field.new("Name", name),
              Approvals::ApprovalSubject::Field.new("Email", email),
            ] of Approvals::ApprovalSubject::Field
          )

          # Create an approval workflow for this user onboarding
          Approvals::Creation::Commands::Request.new.call(
            source_aggregate_type: "User",
            source_aggregate_id: aggregate_id,
            scope_id: scope_id,
            required_approvals: [
              "write_users_onboarding_compliance_approval",
            ],
            actor_id: aggregate.state.requestor_id,
            subject: approval_subject,
          )
        end
      end
    end
  end
end
