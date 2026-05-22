module CrystalBank::Domains::Accounts
  module VirtualAccount
    module Opening
      module Commands
        class ProcessApproval < ES::Command
          def call
            approval_aggregate_id = @aggregate_id.as(UUID)

            approval = Approvals::Aggregate.new(approval_aggregate_id)
            approval.hydrate

            return unless approval.state.source_aggregate_type == "VirtualAccount"

            virtual_account_id = approval.state.source_aggregate_id.as(UUID)

            virtual_account = VirtualAccount::Aggregate.new(virtual_account_id)
            virtual_account.hydrate

            next_version = virtual_account.state.next_version

            event = VirtualAccount::Opening::Events::Accepted.new(
              actor_id: nil,
              aggregate_id: virtual_account_id,
              aggregate_version: next_version,
              command_handler: self.class.to_s
            )

            @event_store.append(event)
          end
        end
      end
    end
  end
end
