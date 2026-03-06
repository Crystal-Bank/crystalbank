module CrystalBank::Domains::Approvals
  module Submission
    module Commands
      # Validates a submission request, records it, and — when all steps are
      # satisfied — emits either AllApproved or Rejected to close the chain.
      class ProcessRequest < ES::Command
        def call
          aggregate_id = @aggregate_id.as(UUID)

          aggregate = Approvals::Aggregate.new(aggregate_id)
          aggregate.hydrate

          requested_event = @event_store
            .load_events(aggregate_id)
            .select(Approvals::Submission::Events::Requested)
            .last?

          raise CrystalBank::Exception::InvalidArgument.new("Submission request event not found") \
            unless requested_event

          body = requested_event.body.as(Approvals::Submission::Events::Requested::Body)
          step_index = body.step_index
          decision = body.decision
          reason = body.reason
          actor_id = requested_event.header.actor_id.not_nil!

          # Validate that the actor holds a permission that satisfies this step
          required_step = aggregate.state.required_approvals[step_index]?
          raise CrystalBank::Exception::InvalidArgument.new("Step #{step_index} not found in approval chain") \
            unless required_step

          actor_permissions = actor_permissions_for(actor_id, aggregate.state.scope_id.not_nil!)
          unless required_step.satisfied_by?(actor_permissions)
            raise CrystalBank::Exception::Authorization.new(
              "Actor does not hold any of the required permissions for step #{step_index}"
            )
          end

          # Prevent the same actor from approving the same step they already acted on
          already_submitted = aggregate.state.submitted_steps.any? { |s| s.step_index == step_index }
          raise CrystalBank::Exception::InvalidArgument.new("Step #{step_index} has already been submitted") \
            if already_submitted

          next_version = aggregate.state.next_version

          # Record the decision
          accepted_event = Approvals::Submission::Events::Accepted.new(
            actor_id: actor_id,
            aggregate_id: aggregate_id,
            aggregate_version: next_version,
            command_handler: self.class.to_s,
            step_index: step_index,
            decision: decision,
            reason: reason
          )
          @event_store.append(accepted_event)

          # Re-hydrate to include the just-appended step
          aggregate = Approvals::Aggregate.new(aggregate_id)
          aggregate.hydrate

          if decision == "rejected"
            rejected_event = Approvals::Submission::Events::Rejected.new(
              actor_id: nil,
              aggregate_id: aggregate_id,
              aggregate_version: aggregate.state.next_version,
              command_handler: self.class.to_s,
              step_index: step_index,
              reason: reason
            )
            @event_store.append(rejected_event)
          elsif aggregate.all_approved?
            all_approved_event = Approvals::Submission::Events::AllApproved.new(
              actor_id: nil,
              aggregate_id: aggregate_id,
              aggregate_version: aggregate.state.next_version,
              command_handler: self.class.to_s
            )
            @event_store.append(all_approved_event)
          end
        end

        private def actor_permissions_for(actor_id : UUID, scope_id : UUID) : Array(CrystalBank::Permissions)
          user_aggregate = CrystalBank::Domains::Users::Aggregate.new(actor_id)
          user_aggregate.hydrate
          role_ids = user_aggregate.state.role_ids

          permissions = [] of CrystalBank::Permissions
          role_ids.each do |role_id|
            role_aggregate = CrystalBank::Domains::Roles::Aggregate.new(role_id)
            role_aggregate.hydrate
            next unless (role_scopes = role_aggregate.state.scopes) && role_scopes.includes?(scope_id)
            if perms = role_aggregate.state.permissions
              permissions.concat(perms)
            end
          end
          permissions.uniq
        end
      end
    end
  end
end
