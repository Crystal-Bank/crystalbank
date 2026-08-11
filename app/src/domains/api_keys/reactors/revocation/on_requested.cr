module CrystalBank::Domains::ApiKeys
  module Reactors
    module Revocation
      # TODO: Run checks to check the legitimacy of the api key revocation
      class OnRequested < ES::Reactor
        def call(event : ApiKeys::Revocation::Events::Requested)
          ApiKeys::Revocation::Commands::AcceptHandler.new(event_store: @event_store, event_handlers: @event_handlers).handle(
            ApiKeys::Revocation::Commands::Accept.new(aggregate_id: event.header.aggregate_id)
          )
        end
      end
    end
  end
end
