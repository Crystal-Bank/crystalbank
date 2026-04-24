module CrystalBank::Domains::Accounts
  module Closure
    module Events
      class Accepted < ES::Event
        include ::ES::EventDSL

        define_event "Account", "account.closure.accepted"
      end
    end
  end
end
