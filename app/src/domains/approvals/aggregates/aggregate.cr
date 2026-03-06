require "./creation"
require "./submission"

module CrystalBank::Domains::Approvals
  class Aggregate < ES::Aggregate
    @@type = "Approval"

    include CrystalBank::Domains::Approvals::Aggregates::Concerns::Creation
    include CrystalBank::Domains::Approvals::Aggregates::Concerns::Submission

    enum Status
      Pending
      Approved
      Rejected
    end

    struct SubmittedStep
      include JSON::Serializable

      getter step_index : Int32
      getter actor_id : UUID
      getter decision : String
      getter reason : String?

      def initialize(@step_index, @actor_id, @decision, @reason)
      end
    end

    struct State < ES::Aggregate::State
      property reference_aggregate_id : UUID?
      property reference_type : String?
      property scope_id : UUID?
      property required_approvals = Array(CrystalBank::Objects::Approval).new
      property submitted_steps = Array(Aggregate::SubmittedStep).new
      property status : Aggregate::Status = Aggregate::Status::Pending
    end

    getter state : State

    def initialize(
      aggregate_id : UUID,
      @event_store : ES::EventStore = ES::Config.event_store,
      @event_handlers : ES::EventHandlers = ES::Config.event_handlers,
    )
      @aggregate_version = 0
      @state = State.new(aggregate_id)
      @state.set_type(@@type)
    end
  end
end
