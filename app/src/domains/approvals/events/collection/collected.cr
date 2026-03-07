module CrystalBank::Domains::Approvals
  module Collection
    module Events
      class Collected < ES::Event
        include ::ES::EventDSL

        define_event "Approval", "approval.collection.collected" do
          attribute :user_id, UUID
          attribute :permissions, Array(String)
        end
      end
    end
  end
end
