module CrystalBank::Domains::ApiKeys
  module Authentication
    module Commands
      class Request < ES::Command
        def call(client_id : String, client_secret : String) : String
          @aggregate_id = UUID.new(client_id)

          # Fetch API key
          aggregate = ApiKeys::Aggregate.new(UUID.new(client_id))
          aggregate.hydrate

          api_key_active = aggregate.state.active
          user_id = aggregate.state.user_id
          encrypted_secret = aggregate.state.encrypted_secret

          # Check integrity of aggregate state
          raise ES::Exception::InvalidState.new("Cannot verify api credentials") if encrypted_secret.nil?
          raise ES::Exception::InvalidState.new("Api key is missing user releation") if user_id.nil?

          # Fail if api key is inactive
          raise CrystalBank::Exception::Authentication.new("Invalid login credentials", HTTP::Status::UNAUTHORIZED) unless api_key_active

          # Extract attributes to local variables
          api_secret = Crypto::Bcrypt::Password.new(encrypted_secret)

          # Check if the secret is valid
          raise CrystalBank::Exception::Authentication.new("Invalid login credentials", HTTP::Status::UNAUTHORIZED) unless api_secret.verify(client_secret)

          # Fetch user
          user = ApiKeys::Repositories::Users.new.fetch!(user_id)

          # TODO: Extract user roles
          uuid = UUID.new("00000000-0000-0000-0000-000000000000")
          user_roles = [uuid]

          # Create JWT and return it
          payload = CrystalBank::Api::JWT.new(roles: user_roles, user_id: user_id)
          JWT.encode(payload, CrystalBank::Env.jwt_private_key, JWT::Algorithm::ES256)
        end
      end
    end
  end
end
