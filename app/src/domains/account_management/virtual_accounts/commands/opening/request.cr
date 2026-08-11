module CrystalBank::Domains::VirtualAccounts
  module Opening
    module Commands
      struct Request < ES::Command
        getter name : String
        getter parent_account_id : UUID
        getter actor_id : UUID

        def initialize(@aggregate_id : UUID, @name, @parent_account_id, @actor_id)
        end
      end

      class RequestHandler < ES::CommandHandler(Request)
        def handle(command : Request)
          # Validate parent exists in projections.accounts (natural depth guard: virtual accounts
          # live only in projections.virtual_accounts and will not be found here)
          parent = Accounts::Queries::Accounts.new.find(command.parent_account_id)
          raise CrystalBank::Exception::InvalidArgument.new("Parent account '#{command.parent_account_id}' does not exist") unless parent
          raise CrystalBank::Exception::InvalidArgument.new("Parent account '#{command.parent_account_id}' is not active") unless parent.status == "active"

          event = VirtualAccounts::Opening::Events::Requested.new(
            actor_id: command.actor_id,
            aggregate_id: command.aggregate_id,
            command_handler: self.class.to_s,
            name: command.name,
            parent_account_id: command.parent_account_id,
            currencies: parent.currencies,
            customer_ids: parent.customer_ids,
            scope_id: parent.scope_id
          )

          @event_store.append(event)
        end
      end
    end
  end
end
