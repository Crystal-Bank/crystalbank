module CrystalBank::Domains::Accounts
  module Blocking
    module Events
      class Removed < ES::Event
        include ::ES::EventDSL

        define_event "Account", "account.blocking.removed" do
          attribute :block_type, CrystalBank::Types::Accounts::BlockType
          attribute :reason, String?
        end
      end
    end
  end
end
