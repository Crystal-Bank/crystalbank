module CrystalBank::Domains::Credentials
  module PasswordSetup
    module Events
      class Completed < ES::Event
        include ::ES::EventDSL

        define_event "Credential", "credential.password_setup.completed" do
          attribute :password_hash, String
        end
      end
    end
  end
end
