module CrystalBank::Domains::Approvals
  module Submission
    module Events
      class Requested < ES::Event
        include ::ES::EventDSL

        define_event "Approval", "approval.submission.requested" do
          # The step index (0-based) this submission targets
          attribute :step_index, Int32
          attribute :decision, String   # "approved" | "rejected"
          attribute :reason, String?
        end
      end
    end
  end
end
