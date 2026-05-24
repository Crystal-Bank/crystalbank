module CrystalBank::Domains::Accounts
  module Blocking
    module Unblocking
      module Events
        class Completed < ES::Event
          include ::ES::EventDSL

          define_event "AccountUnblock", "account.unblocking.completed"
        end
      end
    end
  end
end
