module CrystalBank::Domains::Accounts
  module Opening
    module Commands
      struct Request < ES::Command
        getter name : String
        getter currencies : Array(CrystalBank::Types::Currencies::Supported)
        getter customer_ids : Array(UUID)
        getter scope_id : UUID
        getter type : CrystalBank::Types::Accounts::Type
        getter actor_id : UUID
        getter context : CrystalBank::Api::Context

        def initialize(@aggregate_id : UUID, @name, @currencies, @customer_ids, @scope_id, @type, @actor_id, @context)
        end
      end

      class RequestHandler < ES::CommandHandler(Request)
        def handle(command : Request)
          customer_ids = command.customer_ids

          raise CrystalBank::Exception::InvalidArgument.new("At least one customer ID is required") if customer_ids.empty?

          # Validate all customer IDs exist, belong to the same scope, and are fully onboarded — single query
          active_ids = Customers::Queries::Customers.new.find_all(context: command.context, uuids: customer_ids, scope_id: command.scope_id, status: "active").map(&.id).to_set

          customer_ids.each do |customer_id|
            raise CrystalBank::Exception::InvalidArgument.new("Customer '#{customer_id}' does not exist or is not fully onboarded") unless active_ids.includes?(customer_id)
          end

          # Create the account creation request event
          event = Accounts::Opening::Events::Requested.new(
            actor_id: command.actor_id,
            aggregate_id: command.aggregate_id,
            command_handler: self.class.to_s,
            name: command.name,
            currencies: command.currencies,
            customer_ids: command.customer_ids,
            scope_id: command.scope_id,
            type: command.type
          )

          # Append event to event store
          @event_store.append(event)
        end
      end
    end
  end
end
