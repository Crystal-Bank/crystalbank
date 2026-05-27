module CrystalBank::Domains::Accounts
  module Opening
    module Commands
      class ProcessApproval < ES::Command
        def call
          approval_aggregate_id = @aggregate_id.as(UUID)

          # Hydrate the approval aggregate to get source info
          approval = Approvals::Aggregate.new(approval_aggregate_id)
          approval.hydrate

          # Only process if this approval is for an Account
          return unless approval.state.source_aggregate_type == "Account"

          account_id = approval.state.source_aggregate_id.as(UUID)

          # Build the account aggregate
          account = Accounts::Aggregate.new(account_id)
          account.hydrate

          # Calculate the next aggregate version
          next_version = account.state.next_version

          # Create the account opening acceptance event
          event = Accounts::Opening::Events::Accepted.new(
            actor_id: nil,
            aggregate_id: account_id,
            aggregate_version: next_version,
            command_handler: self.class.to_s
          )

          # Append event to event store
          @event_store.append(event)
        end
      end
    end
  end
end
