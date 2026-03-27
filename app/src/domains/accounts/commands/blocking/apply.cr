module CrystalBank::Domains::Accounts
  module Blocking
    module Commands
      class Apply < ES::Command
        def call(account_id : UUID, block_type : CrystalBank::Types::Accounts::BlockType, reason : String?, c : CrystalBank::Api::Context) : UUID
          actor = c.user_id

          # Hydrate the account aggregate
          aggregate = Accounts::Aggregate.new(account_id)
          aggregate.hydrate

          raise CrystalBank::Exception::InvalidArgument.new("Account '#{account_id}' does not exist or is not open") unless aggregate.state.open
          raise CrystalBank::Exception::InvalidArgument.new("Block '#{block_type}' is already active on account '#{account_id}'") if aggregate.state.active_blocks.includes?(block_type)

          next_version = aggregate.state.next_version

          event = Accounts::Blocking::Events::Applied.new(
            aggregate_id: account_id,
            aggregate_version: next_version,
            actor_id: actor,
            command_handler: self.class.to_s,
            block_type: block_type,
            reason: reason
          )

          @event_store.append(event)

          account_id
        end
      end
    end
  end
end
