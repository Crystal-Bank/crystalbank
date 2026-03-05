module CrystalBank::Domains::Accounts
  module Opening
    module Events
      class Accepted < ES::Event
        include ::ES::EventDSL

        define_event "Account", "account.opening.accepted"
      end
    end
  end
end
