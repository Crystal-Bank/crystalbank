module CrystalBank::Domains::Accounts
  module BlockingRequest
    module Events
      class Requested < ES::Event
        include ::ES::EventDSL

        define_event "AccountBlock", "account.blocking.requested" do
          attribute :account_id, UUID
          attribute :block_type, CrystalBank::Types::Accounts::BlockType
          attribute :reason, String?
        end
      end
    end
  end
end
