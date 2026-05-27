module CrystalBank::Domains::Accounts
  module Closure
    module Closure
      module Events
        class Requested < ES::Event
          include ::ES::EventDSL

          define_event "AccountClosure", "account.closure_request.requested" do
            attribute :account_id, UUID
            attribute :reason, CrystalBank::Types::Accounts::ClosureReason
            attribute :closure_comment, String?
          end
        end
      end
    end
  end
end
