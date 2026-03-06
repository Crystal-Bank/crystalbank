module CrystalBank::Domains::Approvals
  module Decide
    module Commands
      class Request < ES::Command
        DOMAIN_HANDLERS = {
          "account.opening.requested"                           => Accounts::Opening::Commands::ProcessRequest,
          "customer.onboarding.requested"                       => Customers::Onboarding::Commands::ProcessRequest,
          "user.onboarding.requested"                           => Users::Onboarding::Commands::ProcessRequest,
          "user.assign_roles.requested"                         => Users::AssignRoles::Commands::ProcessRequest,
          "role.creation.requested"                             => Roles::Creation::Commands::ProcessRequest,
          "scope.creation.requested"                            => Scopes::Creation::Commands::ProcessRequest,
          "transactions.internal_transfer.initiation.requested" => Transactions::InternalTransfers::Initiation::Commands::ProcessRequest,
          "api_key.generation.requested"                        => ApiKeys::Generation::Commands::ProcessRequest,
          "api_key.revocation.requested"                        => ApiKeys::Revocation::Commands::ProcessRequest,
        }

        def call(
          approval_id : UUID,
          actor_id : UUID,
          decision : Approvals::Aggregate::DecisionType,
          comment : String
        )
          aggregate = Approvals::Aggregate.new(approval_id)
          aggregate.hydrate

          # Workflow must still be pending
          raise CrystalBank::Exception::InvalidArgument.new("Approval workflow is already closed") unless aggregate.state.status == Approvals::Aggregate::Status::Pending

          # Self-approval is not permitted
          raise CrystalBank::Exception::InvalidArgument.new("Self-approval is not permitted") if aggregate.state.requester_id == actor_id

          # Each approver can only vote once
          raise CrystalBank::Exception::InvalidArgument.new("You have already submitted a decision for this approval") if aggregate.state.decisions.any? { |d| d.approver_id == actor_id }

          next_version = aggregate.state.next_version

          decision_event = Approvals::Decision::Events::Made.new(
            actor_id: actor_id,
            command_handler: self.class.to_s,
            aggregate_id: approval_id,
            aggregate_version: next_version,
            approver_id: actor_id,
            decision: decision,
            comment: comment
          )
          @event_store.append(decision_event)

          # Re-hydrate to reflect the new decision in state
          aggregate.hydrate

          if decision == Approvals::Aggregate::DecisionType::Reject
            # A single rejection immediately closes the workflow
            completed_event = Approvals::Workflow::Events::Completed.new(
              actor_id: actor_id,
              command_handler: self.class.to_s,
              aggregate_id: approval_id,
              aggregate_version: aggregate.state.next_version,
              status: Approvals::Aggregate::Status::Rejected
            )
            @event_store.append(completed_event)
          elsif aggregate.state.threshold_met?
            # All required approvers have approved — complete and trigger domain processing
            completed_event = Approvals::Workflow::Events::Completed.new(
              actor_id: actor_id,
              command_handler: self.class.to_s,
              aggregate_id: approval_id,
              aggregate_version: aggregate.state.next_version,
              status: Approvals::Aggregate::Status::Approved
            )
            @event_store.append(completed_event)

            # Dispatch to the originating domain's ProcessRequest command
            handler_class = DOMAIN_HANDLERS[aggregate.state.domain_event_handle]?
            if handler_class
              reference_id = aggregate.state.reference_aggregate_id.as(UUID)
              handler_class.new(reference_id).call
            end
          end

          approval_id
        end
      end
    end
  end
end
