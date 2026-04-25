module CrystalBank::Domains::Scopes
  module Api
    module Requests
      struct CreationRequest
        include JSON::Serializable

        @[JSON::Field(description: "Name of the scope")]
        getter name : String

        @[JSON::Field(description: "ID of the parent scope")]
        getter parent_scope_id : UUID?
      end

      struct NameChangeRequest
        include JSON::Serializable

        @[JSON::Field(description: "ID of the scope to rename")]
        getter scope_id : UUID

        @[JSON::Field(description: "New name for the scope")]
        getter name : String
      end
    end
  end
end
