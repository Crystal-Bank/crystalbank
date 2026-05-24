module CrystalBank::Domains::Accounts
  module Opening
    module Commands
      class ProcessRequest < ES::Command
        def call
          aggregate_id = @aggregate_id.as(UUID)

          # Build the account aggregate
          aggregate = Accounts::Aggregate.new(aggregate_id)
          aggregate.hydrate

          scope_id = aggregate.state.scope_id.as(UUID)

          account_name = aggregate.state.name || "unknown"
          account_type = aggregate.state.type.try(&.to_s) || "unknown"
          currencies = aggregate.state.supported_currencies.map(&.to_s).join(", ")
          approval_subject = Approvals::ApprovalSubject.new(
            title: "Account Opening",
            summary: "#{account_name} (#{account_type})",
            fields: [
              Approvals::ApprovalSubject::Field.new("Name", account_name),
              Approvals::ApprovalSubject::Field.new("Type", account_type),
              Approvals::ApprovalSubject::Field.new("Currencies", currencies),
            ] of Approvals::ApprovalSubject::Field
          )

          # Create an approval workflow for this account opening
          Approvals::Creation::Commands::Request.new.call(
            source_aggregate_type: "Account",
            source_aggregate_id: aggregate_id,
            scope_id: scope_id,
            required_approvals: [
              "write_accounts_opening_compliance_approval",
              # "write_accounts_opening_board_approval",
            ],
            actor_id: aggregate.state.requestor_id,
            subject: approval_subject,
          )
        end
      end
    end
  end
end
