require "./creation"
require "./collection"
require "./rejection"

module CrystalBank::Domains::Approvals
  class Aggregate < ES::Aggregate
    @@type = "Approval"

    include CrystalBank::Domains::Approvals::Aggregates::Concerns::Creation
    include CrystalBank::Domains::Approvals::Aggregates::Concerns::Collection
    include CrystalBank::Domains::Approvals::Aggregates::Concerns::Rejection

    struct CollectedApproval
      include JSON::Serializable

      getter user_id : UUID
      getter permissions : Array(String)
      getter comment : String

      def initialize(@user_id : UUID, @permissions : Array(String), @comment : String = "")
      end
    end

    struct State < ES::Aggregate::State
      property scope_id : UUID?
      property source_aggregate_type : String?
      property source_aggregate_id : UUID?
      property required_approvals = Array(String).new
      property collected_approvals = Array(CollectedApproval).new
      property completed : Bool = false
      property rejected : Bool = false
      property requestor_id : UUID?
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
