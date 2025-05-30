require "./initiation"

module CrystalBank::Domains::Transactions::InternalTransfers
  class Aggregate < ES::Aggregate
    @@type = "Transactions.InternalTransfer"

    include CrystalBank::Domains::Transactions::InternalTransfers::Aggregates::Concerns::Initiation

    struct State < ES::Aggregate::State
      property account_id : UUID?
      property amount : Int64?
      property creditor_account_id : UUID?
      property currency : CrystalBank::Types::Currencies::Supported?
      property debtor_account_id : UUID?
      property remittance_information : String?
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
