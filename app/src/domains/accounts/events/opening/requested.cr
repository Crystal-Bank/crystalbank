module CrystalBank::Domains::Accounts
  module Opening
    module Events
      class Requested < ES::Event
        @@type = "Account"
        @@handle = "account.opening.requested"

        # Data Object for the body of the event
        struct Body < ES::Event::Body
          def initialize(@comment); end
        end

        def initialize(@header : ES::Event::Header, body : JSON::Any)
          @body = Body.from_json(body.to_json)
        end

        def initialize(
          actor : UUID,
          command_handler : String,
          comment = "",
          aggregate_id = UUID.v7
        )
          @header = Header.new(
            actor: actor,
            aggregate_id: aggregate_id,
            aggregate_type: @@type,
            aggregate_version: 1,
            command_handler: command_handler,
            event_handle: @@handle
          )
          @body = Body.new(comment)
        end
      end
    end
  end
end
