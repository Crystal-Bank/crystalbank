module CrystalBank::Domains::Accounts
  module Blocking
    module BlockRequest
      module Events
        class Requested < ES::Event
          include ::ES::EventDSL

          define_event "AccountBlockRequest", "account.block_request.requested" do
            attribute :account_id, UUID
            attribute :block_type, CrystalBank::Types::Accounts::BlockType
            attribute :action, String
            attribute :reason, String?
          end
        end
      end
    end
  end
end
