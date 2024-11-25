module CrystalBank::Domains::Customers
  module Aggregates
    module Concerns
      module Onboarding
        # Apply 'Customers::Onboarding::Events::Accepted' to the aggregate state
        def apply(event : Customers::Onboarding::Events::Accepted)
          @state.increase_version(event.header.aggregate_version)

          body = event.body.as(Customers::Onboarding::Events::Accepted::Body)
          @state.onboarded = true
        end

        # Apply 'Customers::Onboarding::Events::Requested' to the aggregate state
        def apply(event : Customers::Onboarding::Events::Requested)
          @state.increase_version(event.header.aggregate_version)

          body = event.body.as(Customers::Onboarding::Events::Requested::Body)
          @state.name = body.name
          @state.type = body.type
        end
      end
    end
  end
end
