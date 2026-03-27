module CrystalBank::Domains::Accounts
  module Blocking
    module Commands
      # Initiates an unblock request. The removal does not take effect immediately —
      # it is held pending approval from a user with write_accounts_unblocking_approval.
      class Unblock < ES::Command
        def call(r : ::Accounts::Api::Requests::UnblockingCommandRequest, c : CrystalBank::Api::Context) : {block_request_id: UUID, approval_id: UUID}
          actor = c.user_id
          scope = c.scope
          raise CrystalBank::Exception::InvalidArgument.new("Invalid scope") unless scope

          account = ::Accounts::Aggregate.new(r.account_id)
          account.hydrate

          raise CrystalBank::Exception::InvalidArgument.new("Account '#{r.account_id}' does not exist or is not open") unless account.state.open
          raise CrystalBank::Exception::InvalidArgument.new("Block '#{r.block_type}' is not active on account '#{r.account_id}'") unless account.state.active_blocks.includes?(r.block_type)

          unblock_request_event = ::Accounts::Blocking::Unblocking::Events::Requested.new(
            actor_id: actor,
            command_handler: self.class.to_s,
            account_id: r.account_id,
            block_type: r.block_type,
            reason: r.reason
          )
          @event_store.append(unblock_request_event)

          block_request_id = UUID.new(unblock_request_event.header.aggregate_id.to_s)

          approval_id = Approvals::Creation::Commands::Request.new.call(
            source_aggregate_type: "AccountUnblock",
            source_aggregate_id: block_request_id,
            scope_id: scope,
            required_approvals: ["write_accounts_unblocking_approval"],
            actor_id: actor,
          )

          {block_request_id: block_request_id, approval_id: approval_id}
        end
      end
    end
  end
end
