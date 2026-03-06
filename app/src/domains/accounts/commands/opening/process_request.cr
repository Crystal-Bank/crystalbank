module CrystalBank::Domains::Accounts
  module Opening
    module Commands
      class ProcessRequest < ES::Command
        # Approval chain required to open an account.
        # Adjust or replace with [] of CrystalBank::Objects::Approval to skip approvals.
        REQUIRED_APPROVALS = [
          CrystalBank::Objects::Approval.new([CrystalBank::Permissions::APPROVE_accounts_opening_request]),
        ]

        def call
          aggregate_id = @aggregate_id.as(UUID)

          # Build the account aggregate
          aggregate = Accounts::Aggregate.new(aggregate_id)
          aggregate.hydrate

          if REQUIRED_APPROVALS.empty?
            # No approvals configured — accept immediately
            emit_accepted(aggregate_id, aggregate.state.next_version)
          else
            # Ensure an Approval aggregate exists for this request.
            # Approvals::Finalization::Commands::Finalize will emit Accepted
            # once all steps are satisfied.
            ensure_approval_created(aggregate_id, aggregate.state.scope_id.not_nil!)
          end
        end

        private def emit_accepted(aggregate_id : UUID, next_version : Int32)
          event = Accounts::Opening::Events::Accepted.new(
            actor_id: nil,
            aggregate_id: aggregate_id,
            aggregate_version: next_version,
            command_handler: self.class.to_s
          )
          @event_store.append(event)
        end

        private def ensure_approval_created(reference_aggregate_id : UUID, scope_id : UUID)
          already_exists = CrystalBank::Domains::Approvals::Queries::Approvals.new
            .list(cursor: nil, limit: 1, reference_aggregate_id: reference_aggregate_id)
            .any?
          return if already_exists

          CrystalBank::Domains::Approvals::Creation::Commands::Request.new.call(
            reference_aggregate_id: reference_aggregate_id,
            reference_type: "accounts.opening",
            scope_id: scope_id,
            required_approvals: REQUIRED_APPROVALS,
            actor_id: UUID.new("00000000-0000-0000-0000-000000000000")
          )
        end
      end
    end
  end
end
