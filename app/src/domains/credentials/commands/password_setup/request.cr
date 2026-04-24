module CrystalBank::Domains::Credentials
  module PasswordSetup
    module Commands
      class Request < ES::Command
        def call(user_id : UUID, raw_token : String, new_password : String)
          credential = Credentials::Queries::Credentials.new.get(user_id)

          unless credential && credential.invitation_token_hash && credential.invitation_expires_at
            raise CrystalBank::Exception::InvalidArgument.new("Invalid or expired setup token")
          end

          if Time.utc > credential.invitation_expires_at.as(Time)
            raise CrystalBank::Exception::InvalidArgument.new("Setup token has expired")
          end

          stored_hash = Crypto::Bcrypt::Password.new(credential.invitation_token_hash.as(String))
          unless stored_hash.verify(raw_token)
            raise CrystalBank::Exception::InvalidArgument.new("Invalid or expired setup token")
          end

          aggregate = Credentials::Aggregate.new(user_id)
          aggregate.hydrate
          next_version = aggregate.state.next_version

          password_hash = Crypto::Bcrypt::Password.create(new_password, cost: 12).to_s

          event = Credentials::PasswordSetup::Events::Completed.new(
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
