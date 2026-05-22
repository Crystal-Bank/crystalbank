module CrystalBank::Domains::Accounts
  module VirtualAccount
    module Opening
      module Events
        class Accepted < ES::Event
          include ::ES::EventDSL

          define_event "VirtualAccount", "virtual_account.opening.accepted"
        end
      end
    end
  end
end
