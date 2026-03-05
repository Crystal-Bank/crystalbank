module CrystalBank::Domains::Approvals
  class Aggregate < ES::Aggregate
    @@type = "Approval"

    enum Status
      Pending
      Approved
      Rejected
    end

    enum DecisionType
      Approve
      Reject
    end

    struct Decision
      include JSON::Serializable

      property approver_id : UUID
      property decision : DecisionType
      property comment : String

      def initialize(@approver_id : UUID, @decision : DecisionType, @comment : String)
      end
    end

    struct State < ES::Aggregate::State
      property domain_event_handle : String = ""    # e.g. "account.opening.requested"
      property reference_aggregate_id : UUID?       # the domain aggregate being approved
      property scope_id : UUID?                     # scope of the original request
      property requester_id : UUID?                 # who made the original request
      property approval_permission : String = ""    # permission required to approve
      property required_approvers : Int32 = 0       # number of distinct approvers required
      property decisions : Array(Decision) = [] of Decision
      property status : Status = Status::Pending

      def approval_count : Int32
        decisions.count { |d| d.decision == DecisionType::Approve }
      end

      def threshold_met? : Bool
        approval_count >= required_approvers
      end
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
