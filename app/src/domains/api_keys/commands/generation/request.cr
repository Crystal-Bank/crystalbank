module CrystalBank::Domains::ApiKeys
  module Generation
    module Commands
      class Request < ES::Command
        def call(r : ApiKeys::Api::Requests::GenerationRequest, c : CrystalBank::Api::Context) : ::ApiKeys::Api::Responses::GenerationResponse
          actor = c.user_id
          scope = c.scope
          raise CrystalBank::Exception::InvalidArgument.new("Invalid scope") unless scope

          # Check if user is active
          user_active!(UUID.new(r.user_id))

          # Generate an api secret
          api_secret = UUID.random.to_s
          api_secret_encrypted = Crypto::Bcrypt::Password.create(api_secret, cost: 10).to_s

          # Create the api key generation request event
          event = ApiKeys::Generation::Events::Requested.new(
            actor_id: actor,
            api_secret: api_secret_encrypted,
            command_handler: self.class.to_s,
            name: r.name,
            scope_id: scope,
            user_id: r.user_id
          )

          # Append event to event store
          @event_store.append(event)

          # Return the aggregate ID of the newly created api key aggregate
          uuid = UUID.new(event.header.aggregate_id.to_s)
          ApiKeys::Api::Responses::GenerationResponse.new(id: uuid, secret: api_secret)
        end

        private def user_active!(user_id : UUID)
          # TODO: Don't use aggregate here, use a service instead
          user_aggregate = CrystalBank::Domains::Users::Aggregate.new(user_id)
          user_aggregate.hydrate

          raise CrystalBank::Exception::InvalidArgument.new("User '#{user_id}' is not properly onboarded") unless user_aggregate.state.onboarded
        end
      end
    end
  end
end
