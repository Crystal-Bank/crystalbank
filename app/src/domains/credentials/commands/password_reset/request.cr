module CrystalBank::Domains::Credentials
  module PasswordReset
    module Commands
      class Request < ES::Command
        def call(email : String)
          user = Credentials::Repositories::Users.new.fetch_by_email!(email)

          aggregate = Credentials::Aggregate.new(user.id)
          aggregate.hydrate
          next_version = aggregate.state.next_version

          raw_token = Random::Secure.hex(32)
          token_hash = Crypto::Bcrypt::Password.create(raw_token, cost: 10).to_s
          expires_at = Time.utc + CrystalBank::Env.password_reset_token_ttl.seconds

          event = Credentials::PasswordReset::Events::Requested.new(
            actor_id: user.id,
            aggregate_id: user.id,
            aggregate_version: next_version,
            command_handler: self.class.to_s,
            token_hash: token_hash,
            expires_at: expires_at,
          )
          @event_store.append(event)

          CrystalBank::Services::Mailer.new.send_password_reset(user.email, raw_token)
        end
      end
    end
  end
end
