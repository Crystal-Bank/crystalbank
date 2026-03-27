module CrystalBank::Domains::Accounts
  module Blocking
    module Blocking
      module Events
        class Completed < ES::Event
          include ::ES::EventDSL

          define_event "AccountBlock", "account.blocking.completed"
        end
      end
    end
  end
end
