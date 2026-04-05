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

          # Validate all customer IDs exist in the projection under the same scope and are fully onboarded
          found_customers = Customers::Queries::Customers.new.find_all(customer_ids, scope_id: scope)
          found_by_id = found_customers.each_with_object({} of UUID => Customers::Queries::Customers::Customer) { |c, h| h[c.id] = c }

          customer_ids.each do |customer_id|
            customer = found_by_id[customer_id]?
            raise CrystalBank::Exception::InvalidArgument.new("Customer '#{customer_id}' does not exist") unless customer
            raise CrystalBank::Exception::InvalidArgument.new("Customer '#{customer_id}' is not fully onboarded") unless customer.status == "active"
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
