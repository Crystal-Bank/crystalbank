module CrystalBank::Domains::Scopes
  module Api
    module Responses
      # Response to an scope creation request
      struct CreationResponse
        include JSON::Serializable

        @[JSON::Field(format: "uuid", description: "ID of the requested scope")]
        getter id : UUID

        def initialize(@id : UUID); end
      end

      # Respond with a single scope entity
      struct Scope
        include JSON::Serializable

        @[JSON::Field(format: "uuid", description: "ID of the requested scope")]
        getter id : UUID

        @[JSON::Field(description: "Name of the scope")]
        getter name : String

        @[JSON::Field(description: "ID of the parent scope")]
        getter parent_scope_id : UUID?

        def initialize(
          @id : UUID,
          @name : String,
          @parent_scope_id : UUID?,
        ); end
      end
    end
  end
end
