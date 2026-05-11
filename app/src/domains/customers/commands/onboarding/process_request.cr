module CrystalBank::Domains::Customers
  module Onboarding
    module Commands
      class ProcessRequest < ES::Command
        def call
          aggregate_id = @aggregate_id.as(UUID)

          # Build the customer aggregate
          aggregate = Customers::Aggregate.new(aggregate_id)
          aggregate.hydrate

          scope_id = aggregate.state.scope_id.as(UUID)

          name = aggregate.state.name || "unknown"
          customer_type = aggregate.state.type.try(&.to_s) || "unknown"
          approval_subject = Approvals::ApprovalSubject.new(
            title: "Customer Onboarding",
            summary: "#{name} (#{customer_type})",
            fields: [
              Approvals::ApprovalSubject::Field.new("Name", name),
              Approvals::ApprovalSubject::Field.new("Type", customer_type),
            ] of Approvals::ApprovalSubject::Field
          )

          # Create an approval workflow for this customer onboarding
          Approvals::Creation::Commands::Request.new.call(
            source_aggregate_type: "Customer",
            source_aggregate_id: aggregate_id,
            scope_id: scope_id,
            required_approvals: [
              "write_customers_onboarding_compliance_approval",
            ],
            actor_id: aggregate.state.requestor_id,
            subject: approval_subject,
          )
        end
      end
    end
  end
end
