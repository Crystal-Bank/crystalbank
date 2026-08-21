module CrystalBank::Domains::Accounts
  module BlockingRequest
    module Events
      class Completed < ES::Event
        include ::ES::EventDSL

        define_event "AccountBlock", "account.blocking.completed"
      end
    end
  end
end
