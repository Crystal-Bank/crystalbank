module CrystalBank::Domains::Customers
  module Onboarding
    module Events
      class Requested < ES::Event
        include ::ES::EventDSL

        define_event "Customer", "customer.onboarding.requested" do
          attribute :name, String
          attribute :scope_id, UUID
          attribute :type, CrystalBank::Types::Customers::Type
        end
      end
    end
  end
end
