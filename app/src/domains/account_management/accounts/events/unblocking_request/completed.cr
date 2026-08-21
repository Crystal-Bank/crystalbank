module CrystalBank::Domains::Accounts
  module UnblockingRequest
    module Events
      class Completed < ES::Event
        include ::ES::EventDSL

        define_event "AccountUnblock", "account.unblocking.completed"
      end
    end
  end
end
