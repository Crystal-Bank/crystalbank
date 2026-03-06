module CrystalBank::Domains::Approvals
  module Submission
    module Events
      # Emitted when any step is rejected, terminating the entire approval chain.
      class Rejected < ES::Event
        include ::ES::EventDSL

        define_event "Approval", "approval.submission.rejected" do
          attribute :step_index, Int32
          attribute :reason, String?
        end
      end
    end
  end
end
