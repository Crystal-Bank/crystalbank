module CrystalBank::Domains::ApiKeys
  module Authentication
    module Commands
      class Request < ES::Command
        def call(client_id : String, client_secret : String) : String
          @aggregate_id = UUID.new(client_id)

          # # Fetch API key
          # api_key = ApiKeys::Repositories::ApiKeys.new.fetch(@aggregate_id)

          # # Fail if api key is inactive
          # raise CrystalBank::Exception::Authentication.new("Invalid login credentials", HTTP::Status::UNAUTHORIZED) unless api_key.active

          # # Extract attributes to local variables
          # api_secret = Crypto::Bcrypt::Password.new(api_key.encrypted_secret)

          # # Check if the secret is valid
          # raise CrystalBank::Exception::Authentication.new("Invalid login credentials", HTTP::Status::UNAUTHORIZED) unless api_secret.verify(client_secret)

          # # Fetch user
          # user = ApiKeys::Repositories::Users.new.fetch(api_key.user_id)

          # # Fetch roles the user is assigned to
          # user_roles = user.roles

          # # # Create JWT and return it
          # payload = CrystalBank::Objects::JWTPayload.new(roles: user_roles, user_id: @aggregate_id)
          # token = JWT.encode(payload, CrystalBank::Env.jwt_private_key, JWT::Algorithm::ES256)
          # token

          "dummy_token"
        end
      end
    end
  end
end
