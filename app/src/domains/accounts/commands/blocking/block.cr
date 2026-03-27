module CrystalBank::Domains::Accounts
  module Blocking
    module Commands
      # Initiates a block request. The block does not take effect immediately —
      # it is held pending approval from a user with write_accounts_blocking_approval.
      class Block < ES::Command
        def call(r : ::Accounts::Api::Requests::BlockingCommandRequest, c : CrystalBank::Api::Context) : {block_request_id: UUID, approval_id: UUID}
          actor = c.user_id
          scope = c.scope
          raise CrystalBank::Exception::InvalidArgument.new("Invalid scope") unless scope

          account = ::Accounts::Aggregate.new(r.account_id)
          account.hydrate

          raise CrystalBank::Exception::InvalidArgument.new("Account '#{r.account_id}' does not exist or is not open") unless account.state.open
          raise CrystalBank::Exception::InvalidArgument.new("Block '#{r.block_type}' is already active on account '#{r.account_id}'") if account.state.active_blocks.includes?(r.block_type)

          block_request_event = ::Accounts::Blocking::BlockRequest::Events::Requested.new(
            actor_id: actor,
            command_handler: self.class.to_s,
            account_id: r.account_id,
            block_type: r.block_type,
            action: "apply",
            reason: r.reason
          )
          @event_store.append(block_request_event)

          block_request_id = UUID.new(block_request_event.header.aggregate_id.to_s)

          approval_id = Approvals::Creation::Commands::Request.new.call(
            source_aggregate_type: "AccountBlockRequest",
            source_aggregate_id: block_request_id,
            scope_id: scope,
            required_approvals: ["write_accounts_blocking_approval"],
            actor_id: actor,
          )

          {block_request_id: block_request_id, approval_id: approval_id}
        end
      end
    end
  end
end
