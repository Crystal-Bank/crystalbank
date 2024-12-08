module CrystalBank::Domains::ApiKeys
  module Aggregates
    module Concerns
      module Revocation
        # Apply 'ApiKeys::Revocation::Events::Accepted' to the aggregate state
        def apply(event : ApiKeys::Revocation::Events::Accepted)
          @state.increase_version(event.header.aggregate_version)

          body = event.body.as(ApiKeys::Revocation::Events::Accepted::Body)
          @state.active = false
          @state.revoked_at = event.header.created_at
        end

        # Apply 'ApiKeys::Revocation::Events::Requested' to the aggregate state
        def apply(event : ApiKeys::Revocation::Events::Requested)
          @state.increase_version(event.header.aggregate_version)

          body = event.body.as(ApiKeys::Revocation::Events::Requested::Body)
        end
      end
    end
  end
end
