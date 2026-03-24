module CrystalBank::Domains::Approvals
  module Rejection
    module Events
      class Rejected < ES::Event
        include ::ES::EventDSL

        define_event "Approval", "approval.rejection.rejected" do
          attribute :user_id, UUID
        end
      end
    end
  end
end
