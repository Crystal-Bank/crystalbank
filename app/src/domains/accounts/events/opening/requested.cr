module CrystalBank::Domains::Accounts
  module Opening
    module Events
      class Requested < ES::Event
        include ::ES::EventDSL

        define_event "Account", "account.opening.requested" do
          attribute :currencies, Array(CrystalBank::Types::Currencies::Supported)
          attribute :customer_ids, Array(UUID)
          attribute :scope_id, UUID
          attribute :type, CrystalBank::Types::Accounts::Type
        end
      end
    end
  end
end
