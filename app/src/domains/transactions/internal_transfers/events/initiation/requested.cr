module CrystalBank::Domains::Transactions::InternalTransfers
  module Initiation
    module Events
      class Requested < ES::Event
        include ::ES::EventDSL

        define_event "Transaction", "transactions.internal_transfer.initiation.requested" do
          attribute currency, CrystalBank::Types::Currencies::Supported
          attribute amount, Int64
          attribute creditor_account_id, UUID
          attribute debtor_account_id, UUID
          attribute remittance_information, String
          attribute scope_id, UUID
        end

        @@type = "Transaction"
        @@handle = "transactions.internal_transfer.initiation.requested"

        # Data Object for the body of the event
        struct Body < ES::Event::Body
          getter currency : CrystalBank::Types::Currencies::Supported
          getter amount : Int64
          getter creditor_account_id : UUID
          getter debtor_account_id : UUID
          getter remittance_information : String
          getter scope_id : UUID

          def initialize(
            @amount : Int64,
            @comment : String,
            @creditor_account_id : UUID,
            @currency : CrystalBank::Types::Currencies::Supported,
            @debtor_account_id : UUID,
            @remittance_information : String,
            @scope_id : UUID,
          ); end
        end

        def initialize(@header : ES::Event::Header, body : JSON::Any)
          @body = Body.from_json(body.to_json)
        end
      end
    end
  end
end
