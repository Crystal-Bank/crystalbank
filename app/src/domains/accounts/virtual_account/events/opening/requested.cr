module CrystalBank::Domains::Accounts
  module VirtualAccount
    module Opening
      module Events
        class Requested < ES::Event
          include ::ES::EventDSL

          define_event "VirtualAccount", "virtual_account.opening.requested" do
            attribute :name, String
            attribute :parent_account_id, UUID
            attribute :currencies, Array(CrystalBank::Types::Currencies::Supported)
            attribute :customer_ids, Array(UUID)
            attribute :scope_id, UUID
          end
        end
      end
    end
  end
end
