module CrystalBank::Domains::Users
  module RemoveRoles
    module Commands
      class ProcessApproval < ES::Command
        def call
          approval_aggregate_id = @aggregate_id.as(UUID)

          # Hydrate the approval aggregate to get source info
          approval = Approvals::Aggregate.new(approval_aggregate_id)
          approval.hydrate

          # Only process if this approval is for a UserRemoveRoles request
          return unless approval.state.source_aggregate_type == "UserRemoveRoles"

          user_id = approval.state.source_aggregate_id.as(UUID)

          # Build the user aggregate
          user = Users::Aggregate.new(user_id)
          user.hydrate

          # Calculate the next aggregate version
          next_version = user.state.next_version

          # Create the role removal acceptance event
          event = Users::RemoveRoles::Events::Accepted.new(
            actor_id: approval.state.requestor_id,
            aggregate_id: user_id,
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
