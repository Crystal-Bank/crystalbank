module CrystalBank::Domains::Credentials
  module Totp
    module Commands
      class Confirm < ES::Command
        def call(user_id : UUID, code : String)
          credential = Credentials::Queries::Credentials.new.get(user_id)

          unless credential && credential.totp_encrypted_secret
            raise CrystalBank::Exception::InvalidArgument.new("TOTP setup has not been initiated")
          end

          secret = CrystalBank::Services::TOTP.decrypt_secret(credential.totp_encrypted_secret.as(String))
          unless CrystalBank::Services::TOTP.verify(secret, code)
            raise CrystalBank::Exception::InvalidArgument.new("Invalid TOTP code")
          end

          aggregate = Credentials::Aggregate.new(user_id)
          aggregate.hydrate
          next_version = aggregate.state.next_version

          event = Credentials::Totp::Events::Enabled.new(
            actor_id: user_id,
            aggregate_id: user_id,
            aggregate_version: next_version,
            command_handler: self.class.to_s,
          )
          @event_store.append(event)
        end
      end
    end
  end
end
