module CrystalBank::Domains::Credentials
  module Totp
    module Events
      class SetupInitiated < ES::Event
        include ::ES::EventDSL

        define_event "Credential", "credential.totp.setup_initiated" do
          attribute :encrypted_secret, String
        end
      end
    end
  end
end
