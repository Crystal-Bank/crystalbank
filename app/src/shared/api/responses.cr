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

        struct Meta
          include JSON::Serializable

          @[JSON::Field(description: "Indicator if there are more entries")]
          getter has_more : Bool
          @[JSON::Field(description: "Number of entries in the response")]
          getter limit : Int32
          @[JSON::Field(format: "uuid", description: "Next cursor of the list")]
          getter next_cursor : UUID?

          def initialize(@limit : Int32, @next_cursor : UUID?)
            @has_more = !@next_cursor.nil?
          end
        end

        struct Entity(T)
          include JSON::Serializable

          @[JSON::Field(description: "Object type of the entity")]
          getter object : String = T.name

          @[JSON::Field(description: "Attributes of the entity")]
          getter attributes : T

          def initialize(@attributes : T)
            @object = T.to_s.split("::").last.downcase
          end
        end


        @[JSON::Field(description: "Object type of the response", example: "/entities")]
        getter object : String = "list"
        @[JSON::Field(format: "uuid", description: "Url of the entity")]
        getter url : String
        @[JSON::Field(description: "Meta information about the dataset")]
        getter meta : Meta
        @[JSON::Field(format: "array", description: "Array of entities")]
        getter data : Array(Entity(T))

        def initialize(@url : String, data : Array(T), limit : Int32)
          # Remove last element and set cursor
          next_cursor_id = if data.size > limit
                             last = data.last
                             data.pop
                             last.nil? ? nil : last.id
                           end

          @meta = Meta.new(limit, next_cursor_id)
          @data = data.map { |d| Entity(T).new(d) }
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
