module CrystalBank::Domains::Customers
  module Onboarding
    module Events
      class Accepted < ES::Event
        include ::ES::EventDSL

        define_event "Customer", "customer.onboarding.accepted"
      end
    end
  end
end
