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
    end
  end
end
