module CrystalBank::Domains::Users
  module Onboarding
    module Events
      class Accepted < ES::Event
        include ::ES::EventDSL

        define_event "User", "user.onboarding.accepted"
      end
    end
  end
end
