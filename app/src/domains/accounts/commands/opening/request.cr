module CrystalBank::Domains::Accounts
  module Opening
    module Commands
      class Request < ES::Command
        def call(r : Accounts::Api::Requests::OpeningRequest, c : CrystalBank::Api::Context) : UUID
          actor = c.user_id
          scope = c.scope
          raise CrystalBank::Exception::InvalidArgument.new("Invalid scope") unless scope

          customer_ids = r.customer_ids

          raise CrystalBank::Exception::InvalidArgument.new("At least one customer ID is required") if customer_ids.empty?

          # Validate all customer IDs exist, belong to the same scope, and are fully onboarded — single query
          active_ids = Customers::Queries::Customers.new.find_all(context, customer_ids, scope_id: scope, status: "active").map(&.id).to_set

          customer_ids.each do |customer_id|
            raise CrystalBank::Exception::InvalidArgument.new("Customer '#{customer_id}' does not exist or is not fully onboarded") unless active_ids.includes?(customer_id)
          end

          # Create the account creation request event
          event = Accounts::Opening::Events::Requested.new(
            actor_id: actor,
            command_handler: self.class.to_s,
            name: r.name,
            currencies: r.currencies,
            customer_ids: r.customer_ids,
            scope_id: scope,
            type: r.type
          )

          # Append event to event store
          @event_store.append(event)

          # Return the aggregate ID of the newly created account aggregate
          UUID.new(event.header.aggregate_id.to_s)
        end
      end
    end
  end
end
