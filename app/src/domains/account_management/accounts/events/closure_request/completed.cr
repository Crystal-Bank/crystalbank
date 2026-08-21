module CrystalBank::Domains::Accounts
  module ClosureRequest
    module Events
      class Completed < ES::Event
        include ::ES::EventDSL

        define_event "AccountClosure", "account.closure_request.completed"
      end
    end
  end
end
