module CrystalBank::Domains::Accounts
  module Opening
    module Events
      class Requested < ES::Event
        include CrystalBank::Shared::Events::RequestedEventDSL

        define_requested_event "Account", "account.opening.requested" do
          event_field :currencies, Array(CrystalBank::Types::Currencies::Supported)
          event_field :customer_ids, Array(UUID)
          event_field :scope_id, UUID
          event_field :type, CrystalBank::Types::Accounts::Type
        end
      end
    end
  end
end
