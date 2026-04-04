module CrystalBank::Domains::Roles
  module Creation
    module Commands
      class ProcessApproval < ES::Command
        def call
          approval_aggregate_id = @aggregate_id.as(UUID)

          # Hydrate the approval aggregate to get source info
          approval = Approvals::Aggregate.new(approval_aggregate_id)
          approval.hydrate

          # Only process if this approval is for a Role
          return unless approval.state.source_aggregate_type == "Role"

          role_id = approval.state.source_aggregate_id.as(UUID)

          # Build the role aggregate
          role = Roles::Aggregate.new(role_id)
          role.hydrate

          # Calculate the next aggregate version
          next_version = role.state.next_version

          # Create the role creation acceptance event
          event = Roles::Creation::Events::Accepted.new(
            actor_id: nil,
            aggregate_id: role_id,
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
