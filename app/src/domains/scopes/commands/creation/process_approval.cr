module CrystalBank::Domains::Scopes
  module Creation
    module Commands
      class ProcessApproval < ES::Command
        def call
          approval_aggregate_id = @aggregate_id.as(UUID)

          # Hydrate the approval aggregate to get source info
          approval = Approvals::Aggregate.new(approval_aggregate_id)
          approval.hydrate

          # Only process if this approval is for a Scope
          return unless approval.state.source_aggregate_type == "Scope"

          scope_id = approval.state.source_aggregate_id.as(UUID)

          # Build the scope aggregate
          scope = Scopes::Aggregate.new(scope_id)
          scope.hydrate

          # Calculate the next aggregate version
          next_version = scope.state.next_version

          # Create the scope creation acceptance event
          event = Scopes::Creation::Events::Accepted.new(
            actor_id: nil,
            aggregate_id: scope_id,
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
