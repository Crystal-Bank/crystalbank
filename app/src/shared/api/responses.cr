module CrystalBank
  module Api
    module Responses
      # Default Response for resource creation requests
      struct AcceptedResponse
        include JSON::Serializable

        @[JSON::Field(format: "uuid", description: "ID the entity")]
        getter id : UUID

        def initialize(@id : UUID)
        end
      end

      struct ListResponse(T)
        include JSON::Serializable

        @[JSON::Field(description: "Object type of the response", example: "/entities")]
        getter object : String = "list"
        @[JSON::Field(format: "uuid", description: "Url of the entity")]
        getter url : String
        @[JSON::Field(format: "array", description: "Array of entities")]
        getter data : Array(T)

        def initialize(@url : String, @data : Array(T))
        end
      end

      # Default Error Response
      struct ErrorResponse
        include JSON::Serializable
        @[JSON::Field(format: "uuid", description: "ID of the error")]
        getter id : UUID
        @[JSON::Field(description: "Error message")]
        getter message : String
        @[JSON::Field(format: "iso8601", description: "Timestamp of the error")]
        getter timestamp : Time
        @[JSON::Field(description: "Type of the error")]
        getter type : String

        def initialize(@id, @message, @timestamp, @type)
        end
      end
    end
  end
end
