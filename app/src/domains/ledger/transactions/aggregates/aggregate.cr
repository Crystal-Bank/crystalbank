require "./request"

module CrystalBank::Domains::Ledger::Transactions
  class Aggregate < ES::Aggregate
    @@type = "Ledger.Transaction"

    include CrystalBank::Domains::Ledger::Transactions::Aggregates::Concerns::Request

    struct Entry
      include JSON::Serializable

      getter account_id : UUID
      getter direction : String
      getter amount : Int64
      getter entry_type : String

      def initialize(
        @account_id : UUID,
        @direction : String,
        @amount : Int64,
        @entry_type : String,
      )
      end
    end

    struct State < ES::Aggregate::State
      property currency : CrystalBank::Types::Currencies::Supported?
      property entries : Array(Entry)?
      property posting_date : String?
      property value_date : String?
      property remittance_information : String?
      property payment_type : String?
      property external_ref : String?
      property channel : String?
      property scope_id : UUID?
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
