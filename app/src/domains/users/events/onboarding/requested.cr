module CrystalBank::Domains::Users
  module Onboarding
    module Events
      class Requested < ES::Event
        include ::ES::EventDSL

        define_event "User", "user.onboarding.requested" do
          attribute :name, String
          attribute :email, String
          attribute :scope_id, UUID
        end
      end
    end
  end
end
