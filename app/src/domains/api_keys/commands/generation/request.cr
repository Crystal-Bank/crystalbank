module CrystalBank::Domains::ApiKeys
  module Generation
    module Commands
      struct Request < ES::Command
        getter name : String
        getter user_id : UUID
        getter actor_id : UUID
        getter scope_id : UUID

        def initialize(@aggregate_id : UUID, @name, @user_id, @actor_id, @scope_id)
        end
      end

      class RequestHandler < ES::CommandHandler(Request)
        def handle(command : Request) : ::ApiKeys::Api::Responses::GenerationResponse
          # Check if user is active
          user_active!(command.user_id)

          # Generate an api secret
          api_secret = UUID.random.to_s
          api_secret_encrypted = Crypto::Bcrypt::Password.create(api_secret, cost: 10).to_s

          # Create the api key generation request event
          event = ApiKeys::Generation::Events::Requested.new(
            actor_id: command.actor_id,
            aggregate_id: command.aggregate_id,
            api_secret: api_secret_encrypted,
            command_handler: self.class.to_s,
            name: command.name,
            scope_id: command.scope_id,
            user_id: command.user_id
          )

          # Append event to event store
          @event_store.append(event)

          ApiKeys::Api::Responses::GenerationResponse.new(id: command.aggregate_id, secret: api_secret)
        end

        private def user_active!(user_id : UUID)
          # TODO: Don't use aggregate here, use a service instead
          user_aggregate = CrystalBank::Domains::Users::Aggregate.new(user_id, event_store: @event_store, event_handlers: @event_handlers)
          user_aggregate.hydrate

          raise CrystalBank::Exception::InvalidArgument.new("User '#{user_id}' is not properly onboarded") unless user_aggregate.state.onboarded
        end
      end
    end
  end
end
