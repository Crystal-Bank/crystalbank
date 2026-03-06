module CrystalBank::Domains::Approvals
  module Submission
    module Events
      # Emitted once every required step has been approved.
      # Subscribers (e.g. Approvals::Finalization::Commands::Finalize) use this
      # to advance the original action to its Accepted state.
      class AllApproved < ES::Event
        include ::ES::EventDSL

        define_event "Approval", "approval.submission.all_approved"
      end
    end
  end
end
