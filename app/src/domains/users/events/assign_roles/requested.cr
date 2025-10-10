module CrystalBank::Domains::Users
  module AssignRoles
    module Events
      class Requested < ES::Event
        @@type = "User"
        @@handle = "user.assign_roles.requested"

        # Data Object for the body of the event
        struct Body < ES::Event::Body
          getter role_ids : Array(UUID)
          getter scope_id : UUID

          def initialize(
            @comment : String,
            @role_ids : Array(UUID),
            @scope_id : UUID,
          ); end
        end

        def initialize(@header : ES::Event::Header, body : JSON::Any)
          @body = Body.from_json(body.to_json)
        end

        def initialize(
          actor_id : UUID,
          command_handler : String,
          aggregate_id : UUID,
          aggregate_version : Int32,
          role_ids : Array(UUID),
          scope_id : UUID,
          comment = "",
        )
          @header = Header.new(
            actor_id: actor_id,
            aggregate_id: aggregate_id,
            aggregate_type: @@type,
            aggregate_version: aggregate_version,
            command_handler: command_handler,
            event_handle: @@handle
          )
          @body = Body.new(
            comment: comment,
            role_ids: role_ids,
            scope_id: scope_id
          )
        end
      end
    end
  end
end
