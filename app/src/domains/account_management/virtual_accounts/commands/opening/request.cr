module CrystalBank::Domains::VirtualAccounts
  module Opening
    module Commands
      class Request < ES::Command
        def call(r : VirtualAccounts::Api::Requests::VirtualOpeningRequest, parent_account_id : UUID, c : CrystalBank::Api::Context) : UUID
          actor = c.user_id

          # Validate parent exists in projections.accounts (natural depth guard: virtual accounts
          # live only in projections.virtual_accounts and will not be found here)
          parent = Accounts::Queries::Accounts.new.find(parent_account_id)
          raise CrystalBank::Exception::InvalidArgument.new("Parent account '#{parent_account_id}' does not exist") unless parent
          raise CrystalBank::Exception::InvalidArgument.new("Parent account '#{parent_account_id}' is not active") unless parent.status == "active"

          event = VirtualAccounts::Opening::Events::Requested.new(
            actor_id: actor,
            command_handler: self.class.to_s,
            name: r.name,
            parent_account_id: parent_account_id,
            currencies: parent.currencies,
            customer_ids: parent.customer_ids,
            scope_id: parent.scope_id
          )

          @event_store.append(event)

          UUID.new(event.header.aggregate_id.to_s)
        end
      end
    end
  end
end
