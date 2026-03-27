module CrystalBank::Domains::Accounts
  module Blocking
    module BlockRequest
      module Events
        class Completed < ES::Event
          include ::ES::EventDSL

          define_event "AccountBlockRequest", "account.block_request.completed"
        end
      end
    end
  end
end
