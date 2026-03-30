module CrystalBank::Domains::Events
  module Api
    module Responses
      struct Event
        include JSON::Serializable

        @[JSON::Field(format: "uuid")]
        getter id : UUID

        @[JSON::Field(format: "uuid")]
        getter scope_id : UUID

        @[JSON::Field(format: "uuid")]
        getter aggregate_id : UUID

        getter aggregate_type : String
        getter aggregate_version : Int64
        getter event_handle : String

        @[JSON::Field(format: "uuid")]
        getter actor_id : UUID?

        @[JSON::Field(format: "iso8601")]
        getter created_at : Time

        getter header : JSON::Any
        getter body : JSON::Any?

        def initialize(
          @id : UUID,
          @scope_id : UUID,
          @aggregate_id : UUID,
          @aggregate_type : String,
          @aggregate_version : Int64,
          @event_handle : String,
          @actor_id : UUID?,
          @created_at : Time,
          header : String,
          body : String?,
        )
          @header = JSON.parse(header)
          @body = body.try { |b| JSON.parse(b) }
        end
      end
    end
  end
end
