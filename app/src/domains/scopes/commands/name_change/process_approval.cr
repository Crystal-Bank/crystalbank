module CrystalBank::Domains::Scopes
  module NameChange
    module Commands
      class ProcessApproval < ES::Command
        def call
          approval_aggregate_id = @aggregate_id.as(UUID)

          # Hydrate the approval aggregate to get source info
          approval = Approvals::Aggregate.new(approval_aggregate_id)
          approval.hydrate

          # Only process if this approval is for a ScopeNameChange
          return unless approval.state.source_aggregate_type == "ScopeNameChange"

          name_change_request_id = approval.state.source_aggregate_id.as(UUID)

          # Hydrate the name change request aggregate
          name_change_request = Scopes::NameChange::Aggregate.new(name_change_request_id)
          name_change_request.hydrate

          # Guard against double-processing
          return if name_change_request.state.completed

          scope_id = name_change_request.state.scope_id.as(UUID)
          new_name = name_change_request.state.name.as(String)

          # Hydrate the scope aggregate to get the next version
          scope = Scopes::Aggregate.new(scope_id)
          scope.hydrate

          # Apply the approved name onto the Scope aggregate
          accepted_event = Scopes::NameChange::Events::Accepted.new(
            actor_id: approval.state.requestor_id,
            aggregate_id: scope_id,
            aggregate_version: scope.state.next_version,
            command_handler: self.class.to_s,
            name: new_name
          )
          @event_store.append(accepted_event)

          # Mark the name change request itself as completed
          completed_event = Scopes::NameChange::Events::Completed.new(
            actor_id: nil,
            aggregate_id: name_change_request_id,
            aggregate_version: name_change_request.state.next_version,
            command_handler: self.class.to_s
          )
          @event_store.append(completed_event)
        end
      end
    end
  end
end
