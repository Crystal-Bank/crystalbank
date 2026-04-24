module CrystalBank::Domains::Credentials
  module Totp
    module Events
      class Enabled < ES::Event
        include ::ES::EventDSL

        define_event "Credential", "credential.totp.enabled"
      end
    end
  end
end
