module CrystalBank::Domains::Approvals
  module Creation
    module Events
      class Accepted < ES::Event
        include ::ES::EventDSL

        define_event "Approval", "approval.creation.accepted"
      end
    end
  end
end
