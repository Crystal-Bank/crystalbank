module CrystalBank::Domains::Accounts
  module Blocking
    module Aggregates
      module Concerns
        module BlockRequest
          # Apply 'Accounts::Blocking::BlockRequest::Events::Requested' to the aggregate state
          def apply(event : Accounts::Blocking::BlockRequest::Events::Requested)
            @state.increase_version(event.header.aggregate_version)

            body = event.body.as(Accounts::Blocking::BlockRequest::Events::Requested::Body)
            @state.account_id = body.account_id
            @state.block_type = body.block_type
            @state.action = body.action
            @state.reason = body.reason
          end

          # Apply 'Accounts::Blocking::BlockRequest::Events::Completed' to the aggregate state
          def apply(event : Accounts::Blocking::BlockRequest::Events::Completed)
            @state.increase_version(event.header.aggregate_version)
            @state.completed = true
          end
        end
      end
    end
  end
end
