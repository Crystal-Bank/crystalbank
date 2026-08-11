module CrystalBank::Domains::Accounts
  module Blocking
    module Commands
      # Initiates a block request. The block does not take effect immediately —
      # it is held pending approval from a user with write_accounts_blocking_approval.
      struct Block < ES::Command
        getter account_id : UUID
        getter block_type : CrystalBank::Types::Accounts::BlockType
        getter reason : String?
        getter actor_id : UUID
        getter scope_id : UUID

        def initialize(@aggregate_id : UUID, @account_id, @block_type, @reason, @actor_id, @scope_id)
        end
      end

      class BlockHandler < ES::CommandHandler(Block)
        def handle(command : Block)
          account = ::Accounts::Aggregate.new(command.account_id, event_store: @event_store, event_handlers: @event_handlers)
          begin
            account.hydrate
          rescue ES::Exception::NotFound
            raise CrystalBank::Exception::InvalidArgument.new("Account '#{command.account_id}' does not exist or is not open")
          end

          raise CrystalBank::Exception::InvalidArgument.new("Account '#{command.account_id}' does not exist or is not open") unless account.state.open
          raise CrystalBank::Exception::InvalidArgument.new("Block '#{command.block_type}' is already active on account '#{command.account_id}'") if account.state.active_blocks.includes?(command.block_type)

          block_request_id = command.aggregate_id
          block_request_event = ::Accounts::Blocking::Blocking::Events::Requested.new(
            actor_id: command.actor_id,
            aggregate_id: block_request_id,
            command_handler: self.class.to_s,
            account_id: command.account_id,
            block_type: command.block_type,
            reason: command.reason
          )
          @event_store.append(block_request_event)

          # Build approval subject snapshot for the approver's benefit
          account_name = ::Accounts::Queries::Accounts.new.find(command.account_id).try(&.name) || command.account_id.to_s
          block_context_fields = [
            Approvals::ApprovalSubject::Field.new("Account", account_name),
            Approvals::ApprovalSubject::Field.new("Block Type", command.block_type.to_s),
          ] of Approvals::ApprovalSubject::Field
          if (reason = command.reason) && !reason.empty?
            block_context_fields << Approvals::ApprovalSubject::Field.new("Reason", reason)
          end
          approval_subject = Approvals::ApprovalSubject.new(
            title: "Account Block",
            summary: "#{command.block_type} on \"#{account_name}\"",
            fields: block_context_fields
          )

          approval_id = UUID.v7
          Approvals::Creation::Commands::RequestHandler.new(event_store: @event_store, event_handlers: @event_handlers).handle(
            Approvals::Creation::Commands::Request.new(
              aggregate_id: approval_id,
              source_aggregate_type: "AccountBlock",
              source_aggregate_id: block_request_id,
              scope_id: command.scope_id,
              required_approvals: ["write_accounts_blocking_approval"],
              actor_id: command.actor_id,
              subject: approval_subject,
            )
          )

          {block_request_id: block_request_id, approval_id: approval_id}
        end
      end
    end
  end
end
