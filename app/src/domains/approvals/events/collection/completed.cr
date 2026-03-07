module CrystalBank::Domains::Approvals
  module Collection
    module Events
      class Completed < ES::Event
        include ::ES::EventDSL

        define_event "Approval", "approval.collection.completed"
      end
    end
  end
end
