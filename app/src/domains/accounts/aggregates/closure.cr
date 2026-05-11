module CrystalBank::Domains::Accounts
  module Aggregates
    module Concerns
      module Closure
        def apply(event : Accounts::Closure::Events::Requested)
          @state.increase_version(event.header.aggregate_version)
          body = event.body.as(Accounts::Closure::Events::Requested::Body)
          @state.closure_reason = body.reason
          @state.closure_comment = body.closure_comment
          @state.closure_pending = true
        end

        def apply(event : Accounts::Closure::Events::Accepted)
          @state.increase_version(event.header.aggregate_version)
          @state.open = false
          @state.closure_pending = false
        end
      end
    end
  end
end
