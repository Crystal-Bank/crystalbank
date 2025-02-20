module CrystalBank::Domains::Roles
  module Creation
    module Events
      class Requested < ES::Event
        @@type = "Role"
        @@handle = "role.creation.requested"

        # Data Object for the body of the event
        struct Body < ES::Event::Body
          getter name : String
          getter permissions : Array(String)
          getter scopes : Array(UUID)

          def initialize(
            @comment : String,
            @name : String,
            @permissions : Array(String),
            @scopes : Array(UUID),
          ); end
        end

        def initialize(@header : ES::Event::Header, body : JSON::Any)
          @body = Body.from_json(body.to_json)
        end

        def initialize(
          actor_id : UUID,
          command_handler : String,
          name : String,
          permissions : Array(String),
          scopes : Array(UUID),
          comment = "",
          aggregate_id = UUID.v7,
        )
          @header = Header.new(
            actor_id: actor_id,
            aggregate_id: aggregate_id,
            aggregate_type: @@type,
            aggregate_version: 1,
            command_handler: command_handler,
            event_handle: @@handle
          )
          @body = Body.new(
            comment: comment,
            name: name,
            permissions: permissions,
            scopes: scopes
          )
        end
      end
    end
  end
end
