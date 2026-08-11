module CrystalBank::Domains::Accounts
  module Reactors
    module Opening
      class OnRequested < ES::Reactor
        def call(event : Accounts::Opening::Events::Requested)
          aggregate_id = event.header.aggregate_id

          # Build the account aggregate
          aggregate = Accounts::Aggregate.new(aggregate_id, event_store: @event_store, event_handlers: @event_handlers)
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
          Approvals::Creation::Commands::RequestHandler.new(event_store: @event_store, event_handlers: @event_handlers).handle(
            Approvals::Creation::Commands::Request.new(
              aggregate_id: UUID.v7,
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
          )
        end
      end
    end
  end
end
