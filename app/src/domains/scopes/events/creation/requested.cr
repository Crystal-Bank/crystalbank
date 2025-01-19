module CrystalBank::Domains::Scopes
  module Creation
    module Events
      class Requested < ES::Event
        @@type = "Scope"
        @@handle = "scope.creation.requested"

        # Data Object for the body of the event
        struct Body < ES::Event::Body
          getter name : String
          getter parent_scope_id : UUID?

          def initialize(
            @comment : String,
            @name : String,
            @parent_scope_id : UUID?
          ); end
        end

        def initialize(@header : ES::Event::Header, body : JSON::Any)
          @body = Body.from_json(body.to_json)
        end

        def initialize(
          actor_id : UUID,
          command_handler : String,
          name : String,
          parent_scope_id : UUID?,
          comment = "",
          aggregate_id = UUID.v7
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
            parent_scope_id: parent_scope_id
          )
        end
      end
    end
  end
end
