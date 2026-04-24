module CrystalBank::Domains::Credentials
  module PasswordReset
    module Events
      class Requested < ES::Event
        include ::ES::EventDSL

        define_event "Credential", "credential.password_reset.requested" do
          attribute :token_hash, String
          attribute :expires_at, Time
        end
      end
    end
  end
end
