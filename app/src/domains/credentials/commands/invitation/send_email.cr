module CrystalBank::Domains::Credentials
  module Invitation
    module Commands
      class SendEmail < ES::Command
        def call
          user_id = @aggregate_id.as(UUID)

          user = Credentials::Repositories::Users.new.fetch!(user_id)

          aggregate = Credentials::Aggregate.new(user_id)
          aggregate.hydrate
          next_version = aggregate.state.next_version

          raw_token = Random::Secure.hex(32)
          token_hash = Crypto::Bcrypt::Password.create(raw_token, cost: 10).to_s
          expires_at = Time.utc + CrystalBank::Env.invitation_token_ttl.seconds

          event = Credentials::Invitation::Events::Sent.new(
            actor_id: nil,
            aggregate_id: user_id,
            aggregate_version: next_version,
            command_handler: self.class.to_s,
            token_hash: token_hash,
            expires_at: expires_at,
          )
          @event_store.append(event)

          CrystalBank::Services::Mailer.new.send_invitation(user.email, user.name, raw_token)
        end
      end
    end
  end
end
