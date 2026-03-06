module CrystalBank::Domains::Approvals
  module Submission
    module Commands
      # Called from the HTTP API when a user submits an approval decision.
      class Request < ES::Command
        def call(
          approval_id : UUID,
          decision : String,
          reason : String?,
          actor_id : UUID
        ) : UUID
          raise CrystalBank::Exception::InvalidArgument.new("Decision must be 'approved' or 'rejected'") \
            unless ["approved", "rejected"].includes?(decision)

          # Hydrate to determine which step is next and validate actor permission
          aggregate = Approvals::Aggregate.new(approval_id)
          aggregate.hydrate

          raise CrystalBank::Exception::InvalidArgument.new("Approval chain not found") \
            if aggregate.state.required_approvals.empty?

          raise CrystalBank::Exception::InvalidArgument.new("Approval chain is already #{aggregate.state.status.to_s.downcase}") \
            unless aggregate.state.status.pending?

          step_index = aggregate.next_pending_step_index
          raise CrystalBank::Exception::InvalidArgument.new("No pending step found") if step_index.nil?

          event = Approvals::Submission::Events::Requested.new(
            actor_id: actor_id,
            aggregate_id: approval_id,
            aggregate_version: aggregate.state.next_version,
            command_handler: self.class.to_s,
            step_index: step_index,
            decision: decision,
            reason: reason
          )

          @event_store.append(event)

          approval_id
        end
      end
    end
  end
end
