module CrystalBank::Domains::Accounts
  module Blocking
    module Commands
      # Initiates a block or unblock request. The action does not take effect
      # immediately — it is held pending approval from a user with the
      # corresponding approval permission (write_accounts_blocking_approval or
      # write_accounts_unblocking_approval).
      class Request < ES::Command
        def call(r : ::Accounts::Api::Requests::BlockingCommandRequest, c : CrystalBank::Api::Context) : {block_request_id: UUID, approval_id: UUID}
          actor = c.user_id
          scope = c.scope
          raise CrystalBank::Exception::InvalidArgument.new("Invalid scope") unless scope

          # Hydrate the account aggregate to validate preconditions
          account = ::Accounts::Aggregate.new(r.account_id)
          account.hydrate

          raise CrystalBank::Exception::InvalidArgument.new("Account '#{r.account_id}' does not exist or is not open") unless account.state.open

          case r.action
          when "apply"
            raise CrystalBank::Exception::InvalidArgument.new("Block '#{r.block_type}' is already active on account '#{r.account_id}'") if account.state.active_blocks.includes?(r.block_type)
          when "remove"
            raise CrystalBank::Exception::InvalidArgument.new("Block '#{r.block_type}' is not active on account '#{r.account_id}'") unless account.state.active_blocks.includes?(r.block_type)
          else
            raise CrystalBank::Exception::InvalidArgument.new("Unknown action '#{r.action}', expected 'apply' or 'remove'")
          end

          # Create the block request aggregate capturing the intent
          block_request_event = ::Accounts::Blocking::BlockRequest::Events::Requested.new(
            actor_id: actor,
            command_handler: self.class.to_s,
            account_id: r.account_id,
            block_type: r.block_type,
            action: r.action,
            reason: r.reason
          )

          @event_store.append(block_request_event)

          block_request_id = UUID.new(block_request_event.header.aggregate_id.to_s)

          # Determine which approval permission is required based on the action
          required_approval = r.action == "apply" ? "write_accounts_blocking_approval" : "write_accounts_unblocking_approval"

          # Create the approval workflow referencing the block request aggregate
          approval_id = Approvals::Creation::Commands::Request.new.call(
            source_aggregate_type: "AccountBlockRequest",
            source_aggregate_id: block_request_id,
            scope_id: scope,
            required_approvals: [required_approval],
            actor_id: actor,
          )

          {block_request_id: block_request_id, approval_id: approval_id}
        end
      end
    end
  end
end
