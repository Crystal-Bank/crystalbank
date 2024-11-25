module CrystalBank::Domains::Accounts
  module Aggregates
    module Concerns
      module Opening
        # Apply 'Accounts::Opening::Events::Accepted' to the aggregate state
        def apply(event : Accounts::Opening::Events::Accepted)
          @state.increase_version(event.header.aggregate_version)

          body = event.body.as(Accounts::Opening::Events::Accepted::Body)
          @state.open = true
        end

        # Apply 'Accounts::Opening::Events::Requested' to the aggregate state
        def apply(event : Accounts::Opening::Events::Requested)
          @state.increase_version(event.header.aggregate_version)

          body = event.body.as(Accounts::Opening::Events::Requested::Body)
          @state.supported_currencies = body.currencies
          @state.type = body.type
          @state.customer_ids = body.customer_ids
        end
      end
    end
  end
end
