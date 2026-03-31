module CrystalBank::Domains::Events
  module Api
    module Responses
      struct Event
        include JSON::Serializable

        @[JSON::Field(format: "uuid")]
        getter id : UUID

        @[JSON::Field(format: "uuid")]
        getter scope_id : UUID

        getter header : JSON::Any
        getter body : JSON::Any?

        def initialize(
          @id : UUID,
          @scope_id : UUID,
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
