module CrystalBank::Domains::Approvals
  module Submission
    module Events
      # Emitted for every successfully validated approval step (approved or rejected).
      class Accepted < ES::Event
        include ::ES::EventDSL

        define_event "Approval", "approval.submission.accepted" do
          attribute :step_index, Int32
          attribute :decision, String   # "approved" | "rejected"
          attribute :reason, String?
        end
      end
    end
  end
end
