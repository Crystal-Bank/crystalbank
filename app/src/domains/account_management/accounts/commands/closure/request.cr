module CrystalBank::Domains::Accounts
  module Closure
    module Commands
      struct Request < ES::Command
        getter reason : CrystalBank::Types::Accounts::ClosureReason
        getter closure_comment : String?
        getter actor_id : UUID
        getter scope_id : UUID

        def initialize(@aggregate_id : UUID, @reason, @closure_comment, @actor_id, @scope_id)
        end
      end

      class RequestHandler < ES::CommandHandler(Request)
        def handle(command : Request)
          account_id = command.aggregate_id

          account = ::Accounts::Aggregate.new(account_id, event_store: @event_store, event_handlers: @event_handlers)
          begin
            account.hydrate
          rescue ES::Exception::NotFound
            raise CrystalBank::Exception::InvalidArgument.new("Account '#{account_id}' does not exist")
          end

          raise CrystalBank::Exception::InvalidArgument.new("Account '#{account_id}' is not active") unless account.state.open
          raise CrystalBank::Exception::InvalidArgument.new("Account '#{account_id}' already has a pending closure request") if account.state.closure_pending
          raise CrystalBank::Exception::InvalidArgument.new("Account '#{account_id}' has virtual subaccounts that are not inactive; deactivate them first") if ::VirtualAccounts::Queries::VirtualAccounts.new.any_non_inactive?(account_id)

          # Mark the account as closure-pending
          account_event = ::Accounts::Closure::Events::Requested.new(
            actor_id: command.actor_id,
            aggregate_id: account_id,
            aggregate_version: account.state.next_version,
            command_handler: self.class.to_s,
            reason: command.reason,
            closure_comment: command.closure_comment
          )
          @event_store.append(account_event)

          # Create the AccountClosure request aggregate to carry the full intent
          closure_request_id = UUID.v7
          closure_request_event = ::Accounts::ClosureRequest::Events::Requested.new(
            actor_id: command.actor_id,
            aggregate_id: closure_request_id,
            command_handler: self.class.to_s,
            account_id: account_id,
            reason: command.reason,
            closure_comment: command.closure_comment
          )
          @event_store.append(closure_request_event)

          approval_id = UUID.v7
          Approvals::Creation::Commands::RequestHandler.new(event_store: @event_store, event_handlers: @event_handlers).handle(
            Approvals::Creation::Commands::Request.new(
              aggregate_id: approval_id,
              source_aggregate_type: "AccountClosure",
              source_aggregate_id: closure_request_id,
              scope_id: command.scope_id,
              required_approvals: ["write_accounts_closure_approval"],
              actor_id: command.actor_id
            )
          )

          {closure_request_id: closure_request_id, approval_id: approval_id}
        end
      end
    end
  end
end
