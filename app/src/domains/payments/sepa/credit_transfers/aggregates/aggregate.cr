require "./initiation"
require "./execution"

module CrystalBank::Domains::Payments::Sepa::CreditTransfers
  class Aggregate < ES::Aggregate
    @@type = "Payments.Sepa.CreditTransfer"

    include CrystalBank::Domains::Payments::Sepa::CreditTransfers::Aggregates::Concerns::Initiation
    include CrystalBank::Domains::Payments::Sepa::CreditTransfers::Aggregates::Concerns::Execution

    struct State < ES::Aggregate::State
      property end_to_end_id : String?
      property debtor_account_id : UUID?
      property settlement_account_id : UUID?
      property creditor_iban : String?
      property creditor_name : String?
      property creditor_bic : String?
      property amount : Int64?
      property execution_date : Time?
      property remittance_information : String?
      property scope_id : UUID?
      property ledger_transaction_id : UUID?
      property status : String?
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
