require "./concerns/responses"

module CrystalBank::Domains::Events
  module Api
    class Events < CrystalBank::Api::Base
      include CrystalBank::Domains::Events::Api::Responses
      base "/events"

      # List
      # List domain events visible to the caller
      #
      # Required permission:
      # - **read_events_list**
      @[AC::Route::GET("/")]
      def list_events(
        @[AC::Param::Info(description: "Optional cursor parameter for pagination")]
        cursor : UUID?,
        @[AC::Param::Info(description: "Limit parameter for pagination (default 20)", example: "20")]
        limit : Int32 = 20,
        @[AC::Param::Info(description: "Filter by aggregate type (e.g. User, Account, Approval)")]
        aggregate_type : String? = nil,
        @[AC::Param::Info(description: "Filter by event handle (e.g. user.onboarding.requested)")]
        event_handle : String? = nil,
      ) : ListResponse(Responses::Event)
        authorized?("read_events_list", request_scope: false)

        events = ::Events::Queries::Events.new.list(
          context,
          cursor: cursor,
          limit: limit + 1,
          aggregate_type: aggregate_type,
          event_handle: event_handle,
        ).map do |e|
          Responses::Event.new(
            e.id,
            e.scope_id,
            e.aggregate_id,
            e.aggregate_type,
            e.aggregate_version,
            e.event_handle,
            e.actor_id,
            e.created_at,
            e.header,
            e.body,
          )
        end

        ListResponse(Responses::Event).new(
          url: request.resource,
          data: events,
          limit: limit,
        )
      end
    end
  end
end
