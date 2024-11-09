module CrystalBank::Domains::Transactions::InternalTransfers
  module Initiation
    module Events
      class Requested < ES::Event
        @@type = "Transaction"
        @@handle = "transactions.internal_transfer.initiation.requested"

        # Data Object for the body of the event
        struct Body < ES::Event::Body
          getter currency : CrystalBank::Types::Currencies::Supported
          getter amount : Int64
          getter creditor_account_id : UUID
          getter debtor_account_id : UUID
          getter remittance_information : String

          def initialize(
            @amount : Int64,
            @comment : String,
            @creditor_account_id : UUID,
            @currency : CrystalBank::Types::Currencies::Supported,
            @debtor_account_id : UUID,
            @remittance_information : String
          ); end
        end

        def initialize(@header : ES::Event::Header, body : JSON::Any)
          @body = Body.from_json(body.to_json)
        end

        def initialize(
          actor_id : UUID,
          command_handler : String,
          amount : Int64,
          creditor_account_id : UUID,
          currency : CrystalBank::Types::Currencies::Supported,
          debtor_account_id : UUID,
          remittance_information = "",
          comment = "",
          aggregate_id = UUID.v7
        )
          @header = Header.new(
            actor_id: actor_id,
            aggregate_id: aggregate_id,
            aggregate_type: @@type,
            aggregate_version: 1,
            command_handler: command_handler,
            event_handle: @@handle
          )
          @body = Body.new(
            amount: amount,
            comment: comment,
            creditor_account_id: creditor_account_id,
            currency: currency,
            debtor_account_id: debtor_account_id,
            remittance_information: remittance_information
          )
        end
      end
    end
  end
end
