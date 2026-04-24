module CrystalBank::Domains::Accounts
  module Closure
    module Closure
      module Events
        class Completed < ES::Event
          include ::ES::EventDSL

          define_event "AccountClosure", "account.closure_request.completed"
        end
      end
    end
  end
end
