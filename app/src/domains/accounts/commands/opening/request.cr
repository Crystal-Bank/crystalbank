module CrystalBank::Domains::Accounts
  module Opening
    module Commands
      class Request < ES::Command
        def call(r : Accounts::Api::Requests::OpeningRequest, c : CrystalBank::Api::Context) : UUID
          actor = c.user_id
          scope = c.scope
          raise CrystalBank::Exception::InvalidArgument.new("Invalid scope") unless scope

          customer_ids = r.customer_ids

          # Check if customer ids are eligable to open an account, raise exception if not
          customer_ids.each { |c| customer_eligable!(UUID.new(c)) }

          # Create the account creation request event
          event = Accounts::Opening::Events::Requested.new(
            actor_id: actor,
            command_handler: self.class.to_s,
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

        private def customer_eligable!(customer_id : UUID)
          customer_aggregate = CrystalBank::Domains::Customers::Aggregate.new(customer_id)
          customer_aggregate.hydrate

          raise CrystalBank::Exception::InvalidArgument.new("Customer '#{customer_id}' is not properly onboarded") unless customer_aggregate.state.onboarded
        end
      end
    end
  end
end
