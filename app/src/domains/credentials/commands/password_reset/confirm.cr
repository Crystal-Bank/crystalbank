module CrystalBank::Domains::Credentials
  module PasswordReset
    module Commands
      class Confirm < ES::Command
        def call(user_id : UUID, raw_token : String, new_password : String)
          credential = Credentials::Queries::Credentials.new.get(user_id)

          unless credential && credential.reset_token_hash && credential.reset_expires_at
            raise CrystalBank::Exception::InvalidArgument.new("Invalid or expired reset token")
          end

          if Time.utc > credential.reset_expires_at.as(Time)
            raise CrystalBank::Exception::InvalidArgument.new("Reset token has expired")
          end

          stored_hash = Crypto::Bcrypt::Password.new(credential.reset_token_hash.as(String))
          unless stored_hash.verify(raw_token)
            raise CrystalBank::Exception::InvalidArgument.new("Invalid or expired reset token")
          end

          aggregate = Credentials::Aggregate.new(user_id)
          aggregate.hydrate
          next_version = aggregate.state.next_version

          password_hash = Crypto::Bcrypt::Password.create(new_password, cost: 12).to_s

          event = Credentials::PasswordReset::Events::Confirmed.new(
            actor_id: user_id,
            aggregate_id: user_id,
            aggregate_version: next_version,
            command_handler: self.class.to_s,
            password_hash: password_hash,
          )
          @event_store.append(event)
        end
      end
    end
  end
end
