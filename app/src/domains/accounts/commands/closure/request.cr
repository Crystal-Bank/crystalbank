module CrystalBank::Domains::Accounts
  module Closure
    module Commands
      class Request < ES::Command
        def call(r : Accounts::Api::Requests::ClosureRequest, account_id : UUID, c : CrystalBank::Api::Context) : {closure_request_id: UUID, approval_id: UUID}
          actor = c.user_id
          scope = c.scope
          raise CrystalBank::Exception::InvalidArgument.new("Invalid scope") unless scope

          account = ::Accounts::Aggregate.new(account_id)
          begin
            account.hydrate
          rescue ES::Exception::NotFound
            raise CrystalBank::Exception::InvalidArgument.new("Account '#{account_id}' does not exist")
          end

          raise CrystalBank::Exception::InvalidArgument.new("Account '#{account_id}' is not active") unless account.state.open
          raise CrystalBank::Exception::InvalidArgument.new("Account '#{account_id}' already has a pending closure request") if account.state.closure_pending

          # Mark the account as closure-pending
          account_event = ::Accounts::Closure::Events::Requested.new(
            actor_id: actor,
            aggregate_id: account_id,
            aggregate_version: account.state.next_version,
            command_handler: self.class.to_s,
            reason: r.reason,
            closure_comment: r.closure_comment
          )
          @event_store.append(account_event)

          # Create the AccountClosure request aggregate to carry the full intent
          closure_request_event = ::Accounts::Closure::Closure::Events::Requested.new(
            actor_id: actor,
            command_handler: self.class.to_s,
            account_id: account_id,
            reason: r.reason,
            closure_comment: r.closure_comment
          )
          @event_store.append(closure_request_event)

          closure_request_id = UUID.new(closure_request_event.header.aggregate_id.to_s)

          approval_id = Approvals::Creation::Commands::Request.new.call(
            source_aggregate_type: "AccountClosure",
            source_aggregate_id: closure_request_id,
            scope_id: scope,
            required_approvals: ["write_accounts_closure_approval"],
            actor_id: actor
          )

          {closure_request_id: closure_request_id, approval_id: approval_id}
        end
      end
    end
  end
end
