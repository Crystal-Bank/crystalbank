require "./concerns/requests"
require "./concerns/responses"

module CrystalBank::Domains::Payments::Sepa::CreditTransfers
  module Api
    class CreditTransfers < CrystalBank::Api::Base
      include CrystalBank::Domains::Payments::Sepa::CreditTransfers::Api::Requests
      include CrystalBank::Domains::Payments::Sepa::CreditTransfers::Api::Responses
      base "/payments/sepa/credit-transfers"

      # Submit a SEPA Credit Transfer
      #
      # Creates a new SEPA Credit Transfer and opens an approval workflow.
      # The payment will be executed (i.e. ledger postings created) once the
      # required approval has been collected.
      #
      # Required permission:
      # - **write_payments_sepa_credit_transfers_request**
      @[AC::Route::POST("/", body: :r)]
      def create(r : CreditTransferRequest) : Responses::CreditTransferResponse
        authorized?("write_payments_sepa_credit_transfers_request")

        result = ::Payments::Sepa::CreditTransfers::Initiation::Commands::Request.new.call(r, context)

        Responses::CreditTransferResponse.new(result[:payment_id])
      end

      # List SEPA Credit Transfers
      #
      # Returns a paginated list of SEPA Credit Transfers visible to the caller.
      #
      # Required permission:
      # - **read_payments_sepa_credit_transfers_list**
      @[AC::Route::GET("/")]
      def list(
        @[AC::Param::Info(description: "Optional cursor for pagination")]
        cursor : UUID?,
        @[AC::Param::Info(description: "Page size (default 20)", example: "20")]
        limit : Int32 = 20,
        @[AC::Param::Info(description: "Filter by status: pending or executed")]
        status : String? = nil,
      ) : ListResponse(Responses::CreditTransfer)
        authorized?("read_payments_sepa_credit_transfers_list", request_scope: false)

        transfers = ::Payments::Sepa::CreditTransfers::Queries::CreditTransfers.new
          .list(context, cursor: cursor, limit: limit + 1, status: status)
          .map do |t|
            Responses::CreditTransfer.new(
              id: t.uuid,
              scope_id: t.scope_id,
              end_to_end_id: t.end_to_end_id,
              debtor_account_id: t.debtor_account_id,
              creditor_iban: t.creditor_iban,
              creditor_name: t.creditor_name,
              creditor_bic: t.creditor_bic,
              amount: t.amount,
              currency: t.currency,
              execution_date: t.execution_date.to_rfc3339,
              remittance_information: t.remittance_information,
              status: t.status,
              ledger_transaction_id: t.ledger_transaction_id,
              created_at: t.created_at.to_rfc3339,
            )
          end

        ListResponse(Responses::CreditTransfer).new(
          url: request.resource,
          data: transfers,
          limit: limit,
        )
      end
    end
  end
end
