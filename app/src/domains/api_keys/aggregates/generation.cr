module CrystalBank::Domains::ApiKeys
  module Aggregates
    module Concerns
      module Generation
        # Apply 'ApiKeys::Generation::Events::Accepted' to the aggregate state
        def apply(event : ApiKeys::Generation::Events::Accepted)
          @state.increase_version(event.header.aggregate_version)

          body = event.body.as(ApiKeys::Generation::Events::Accepted::Body)
          @state.active = true
        end

        # Apply 'ApiKeys::Generation::Events::Requested' to the aggregate state
        def apply(event : ApiKeys::Generation::Events::Requested)
          @state.increase_version(event.header.aggregate_version)

          body = event.body.as(ApiKeys::Generation::Events::Requested::Body)

          @state.name = body.name
          @state.user_id = body.user_id
          @state.encrypted_secret = body.api_secret
          @state.scope_id = body.scope_id
        end
      end
    end
  end
end
