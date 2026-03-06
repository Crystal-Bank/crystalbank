module CrystalBank::Domains::Approvals
  module Aggregates
    module Concerns
      module Submission
        def apply(event : Approvals::Submission::Events::Accepted)
          @state.increase_version(event.header.aggregate_version)

          body = event.body.as(Approvals::Submission::Events::Accepted::Body)
          @state.submitted_steps << Aggregate::SubmittedStep.new(
            step_index: body.step_index,
            actor_id: event.header.actor_id.not_nil!,
            decision: body.decision,
            reason: body.reason
          )
        end

        def apply(event : Approvals::Submission::Events::AllApproved)
          @state.increase_version(event.header.aggregate_version)
          @state.status = Aggregate::Status::Approved
        end

        def apply(event : Approvals::Submission::Events::Rejected)
          @state.increase_version(event.header.aggregate_version)
          @state.status = Aggregate::Status::Rejected
        end

        # Returns the 0-based index of the next step awaiting approval,
        # or nil when all steps are already submitted.
        def next_pending_step_index : Int32?
          submitted = @state.submitted_steps.map(&.step_index).to_set
          @state.required_approvals.each_with_index do |_, idx|
            return idx unless submitted.includes?(idx)
          end
          nil
        end

        # True when every required step carries an "approved" decision.
        def all_approved? : Bool
          return false if @state.required_approvals.empty?
          approved_indices = @state.submitted_steps
            .select { |s| s.decision == "approved" }
            .map(&.step_index)
            .to_set
          @state.required_approvals.each_with_index.all? { |_, idx| approved_indices.includes?(idx) }
        end
      end
    end
  end
end
