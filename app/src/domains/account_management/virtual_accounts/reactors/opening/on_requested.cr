module CrystalBank::Domains::VirtualAccounts
  module Reactors
    module Opening
      class OnRequested < ES::Reactor
        def call(event : VirtualAccounts::Opening::Events::Requested)
          aggregate_id = event.header.aggregate_id

          aggregate = VirtualAccounts::Aggregate.new(aggregate_id, event_store: @event_store, event_handlers: @event_handlers)
          aggregate.hydrate

          scope_id = aggregate.state.scope_id.as(UUID)
          parent_account_id = aggregate.state.parent_account_id.as(UUID)
          virtual_name = aggregate.state.name || "unknown"
          currencies = aggregate.state.supported_currencies.map(&.to_s).join(", ")

          approval_subject = Approvals::ApprovalSubject.new(
            title: "Virtual Account Opening",
            summary: virtual_name,
            fields: [
              Approvals::ApprovalSubject::Field.new("Name", virtual_name),
              Approvals::ApprovalSubject::Field.new("Parent Account", parent_account_id.to_s),
              Approvals::ApprovalSubject::Field.new("Currencies (inherited)", currencies),
            ] of Approvals::ApprovalSubject::Field
          )

          Approvals::Creation::Commands::RequestHandler.new(event_store: @event_store, event_handlers: @event_handlers).handle(
            Approvals::Creation::Commands::Request.new(
              aggregate_id: UUID.v7,
              source_aggregate_type: "VirtualAccount",
              source_aggregate_id: aggregate_id,
              scope_id: scope_id,
              required_approvals: ["write_accounts_virtual_opening_approval"],
              actor_id: aggregate.state.requestor_id,
              subject: approval_subject,
            )
          )
        end
      end
    end
  end
end
