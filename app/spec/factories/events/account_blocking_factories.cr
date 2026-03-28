module Test::Account::Events
  module Blocking
    class Applied
      def create(
        aggr_id : UUID,
        block_type : CrystalBank::Types::Accounts::BlockType = CrystalBank::Types::Accounts::BlockType::COMPLIANCE_BLOCK,
        aggregate_version : Int32 = 3,
        actor_id : UUID = UUID.new("00000000-0000-0000-0000-000000000000"),
        reason : String? = nil
      ) : Accounts::Blocking::Events::Applied
        Accounts::Blocking::Events::Applied.new(
          actor_id: actor_id,
          aggregate_id: aggr_id,
          aggregate_version: aggregate_version,
          command_handler: "test",
          block_type: block_type,
          reason: reason
        )
      end
    end

    class Removed
      def create(
        aggr_id : UUID,
        block_type : CrystalBank::Types::Accounts::BlockType = CrystalBank::Types::Accounts::BlockType::COMPLIANCE_BLOCK,
        aggregate_version : Int32 = 4,
        actor_id : UUID = UUID.new("00000000-0000-0000-0000-000000000000"),
        reason : String? = nil
      ) : Accounts::Blocking::Events::Removed
        Accounts::Blocking::Events::Removed.new(
          actor_id: actor_id,
          aggregate_id: aggr_id,
          aggregate_version: aggregate_version,
          command_handler: "test",
          block_type: block_type,
          reason: reason
        )
      end
    end

    module Blocking
      class Requested
        def create(
          aggr_id : UUID,
          account_id : UUID,
          block_type : CrystalBank::Types::Accounts::BlockType = CrystalBank::Types::Accounts::BlockType::COMPLIANCE_BLOCK,
          actor_id : UUID = UUID.new("00000000-0000-0000-0000-000000000000"),
          reason : String? = nil
        ) : Accounts::Blocking::Blocking::Events::Requested
          Accounts::Blocking::Blocking::Events::Requested.new(
            actor_id: actor_id,
            aggregate_id: aggr_id,
            command_handler: "test",
            account_id: account_id,
            block_type: block_type,
            reason: reason
          )
        end
      end

      class Completed
        def create(
          aggr_id : UUID,
          aggregate_version : Int32 = 2
        ) : Accounts::Blocking::Blocking::Events::Completed
          Accounts::Blocking::Blocking::Events::Completed.new(
            actor_id: nil,
            aggregate_id: aggr_id,
            aggregate_version: aggregate_version,
            command_handler: "test"
          )
        end
      end
    end

    module Unblocking
      class Requested
        def create(
          aggr_id : UUID,
          account_id : UUID,
          block_type : CrystalBank::Types::Accounts::BlockType = CrystalBank::Types::Accounts::BlockType::COMPLIANCE_BLOCK,
          actor_id : UUID = UUID.new("00000000-0000-0000-0000-000000000000"),
          reason : String? = nil
        ) : Accounts::Blocking::Unblocking::Events::Requested
          Accounts::Blocking::Unblocking::Events::Requested.new(
            actor_id: actor_id,
            aggregate_id: aggr_id,
            command_handler: "test",
            account_id: account_id,
            block_type: block_type,
            reason: reason
          )
        end
      end

      class Completed
        def create(
          aggr_id : UUID,
          aggregate_version : Int32 = 2
        ) : Accounts::Blocking::Unblocking::Events::Completed
          Accounts::Blocking::Unblocking::Events::Completed.new(
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
