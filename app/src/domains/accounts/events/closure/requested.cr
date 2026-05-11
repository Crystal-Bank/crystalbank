module CrystalBank::Domains::Accounts
  module Closure
    module Events
      class Requested < ES::Event
        include ::ES::EventDSL

        define_event "Account", "account.closure.requested" do
          attribute :reason, CrystalBank::Types::Accounts::ClosureReason
          attribute :closure_comment, String?
        end
      end
    end
  end
end
