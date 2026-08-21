module Test::Account::Events
  module Closure
    class Requested
      def create(
        aggr_id : UUID,
        reason : CrystalBank::Types::Accounts::ClosureReason = CrystalBank::Types::Accounts::ClosureReason::BY_CUSTOMER,
        closure_comment : String? = nil,
        aggregate_version : Int32 = 3,
        actor_id : UUID = UUID.new("00000000-0000-0000-0000-000000000000"),
      ) : Accounts::Closure::Events::Requested
        Accounts::Closure::Events::Requested.new(
          actor_id: actor_id,
          aggregate_id: aggr_id,
          aggregate_version: aggregate_version,
          command_handler: "test",
          reason: reason,
          closure_comment: closure_comment
        )
      end
    end

    class Accepted
      def create(
        aggr_id : UUID,
        aggregate_version : Int32 = 4,
      ) : Accounts::Closure::Events::Accepted
        Accounts::Closure::Events::Accepted.new(
          actor_id: nil,
          aggregate_id: aggr_id,
          aggregate_version: aggregate_version,
          command_handler: "test"
        )
      end
    end

    module ClosureRequest
      class Requested
        def create(
          aggr_id : UUID,
          account_id : UUID,
          reason : CrystalBank::Types::Accounts::ClosureReason = CrystalBank::Types::Accounts::ClosureReason::BY_CUSTOMER,
          closure_comment : String? = nil,
          actor_id : UUID = UUID.new("00000000-0000-0000-0000-000000000000"),
        ) : Accounts::ClosureRequest::Events::Requested
          Accounts::ClosureRequest::Events::Requested.new(
            actor_id: actor_id,
            aggregate_id: aggr_id,
            command_handler: "test",
            account_id: account_id,
            reason: reason,
            closure_comment: closure_comment
          )
        end
      end

      class Completed
        def create(
          aggr_id : UUID,
          aggregate_version : Int32 = 2,
        ) : Accounts::ClosureRequest::Events::Completed
          Accounts::ClosureRequest::Events::Completed.new(
            actor_id: nil,
            aggregate_id: aggr_id,
            aggregate_version: aggregate_version,
            command_handler: "test"
          )
        end
      end
    end
  end
end
