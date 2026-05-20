module CrystalBank::Domains::Accounts
  module Virtual
    module Opening
      module Commands
        class ProcessRequest < ES::Command
          def call
            aggregate_id = @aggregate_id.as(UUID)

            aggregate = Virtual::Aggregate.new(aggregate_id)
            aggregate.hydrate

            scope_id = aggregate.state.scope_id.as(UUID)
            parent_account_id = aggregate.state.parent_account_id.as(UUID)
            virtual_name = aggregate.state.name || "unknown"

            approval_subject = Approvals::ApprovalSubject.new(
              title: "Virtual Account Opening",
              summary: virtual_name,
              fields: [
                Approvals::ApprovalSubject::Field.new("Name", virtual_name),
                Approvals::ApprovalSubject::Field.new("Parent Account", parent_account_id.to_s),
              ] of Approvals::ApprovalSubject::Field
            )

            Approvals::Creation::Commands::Request.new.call(
              source_aggregate_type: "VirtualAccount",
              source_aggregate_id: aggregate_id,
              scope_id: scope_id,
              required_approvals: ["write_accounts_virtual_opening_approval"],
              actor_id: aggregate.state.requestor_id,
              subject: approval_subject,
            )
          end
        end
      end
    end
  end
end
