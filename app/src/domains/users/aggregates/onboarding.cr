module CrystalBank::Domains::Users
  module Aggregates
    module Concerns
      module Onboarding
        # Apply 'Users::Onboarding::Events::Accepted' to the aggregate state
        def apply(event : Users::Onboarding::Events::Accepted)
          @state.increase_version(event.header.aggregate_version)

          body = event.body.as(Users::Onboarding::Events::Accepted::Body)
          @state.onboarded = true
        end

        # Apply 'Users::Onboarding::Events::Requested' to the aggregate state
        def apply(event : Users::Onboarding::Events::Requested)
          @state.increase_version(event.header.aggregate_version)

          body = event.body.as(Users::Onboarding::Events::Requested::Body)
          @state.name = body.name
          @state.email = body.email
          @state.scope_id = body.scope_id
        end
      end
    end
  end
end
