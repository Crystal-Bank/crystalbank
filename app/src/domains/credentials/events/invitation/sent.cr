module CrystalBank::Domains::Credentials
  module Invitation
    module Events
      class Sent < ES::Event
        include ::ES::EventDSL

        define_event "Credential", "credential.invitation.sent" do
          attribute :token_hash, String
          attribute :expires_at, Time
        end
      end
    end
  end
end
