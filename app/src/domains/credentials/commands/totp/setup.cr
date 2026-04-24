module CrystalBank::Domains::Credentials
  module Totp
    module Commands
      class Setup < ES::Command
        def call(user_id : UUID) : {String, String}
          credential = Credentials::Queries::Credentials.new.get(user_id)
          raise ES::Exception::NotFound.new("Credentials not found for user '#{user_id}'") unless credential

          aggregate = Credentials::Aggregate.new(user_id)
          aggregate.hydrate
          next_version = aggregate.state.next_version

          secret = CrystalBank::Services::TOTP.generate_secret
          encrypted = CrystalBank::Services::TOTP.encrypt_secret(secret)

          user = Credentials::Repositories::Users.new.fetch!(user_id)

          event = Credentials::Totp::Events::SetupInitiated.new(
            actor_id: user_id,
            aggregate_id: user_id,
            aggregate_version: next_version,
            command_handler: self.class.to_s,
            encrypted_secret: encrypted,
          )
          @event_store.append(event)

          uri = CrystalBank::Services::TOTP.uri(secret, user.email)
          {secret, uri}
        end
      end
    end
  end
end
