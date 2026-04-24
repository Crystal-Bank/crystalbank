module CrystalBank::Domains::Credentials
  module PasswordReset
    module Events
      class Confirmed < ES::Event
        include ::ES::EventDSL

        define_event "Credential", "credential.password_reset.confirmed" do
          attribute :password_hash, String
        end
      end
    end
  end
end
