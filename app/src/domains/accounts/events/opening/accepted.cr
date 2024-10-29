module CrystalBank::Domains::Accounts
  module Opening
    module Events
      class Accepted < ES::Event
        @@type = "Account"
        @@handle = "account.opening.accepted"

        # Data Object for the body of the event
        struct Body < ES::Event::Body
          def initialize(@comment); end
        end

        def initialize(@header : ES::Event::Header, body : JSON::Any)
          @body = Body.from_json(body.to_json)
        end

        def initialize(
          command_handler : String,
          aggregate_id : UUID,
          aggregate_version : Int32,
          actor : UUID?,
          comment = ""
        )
          @header = Header.new(
            actor: actor,
            aggregate_id: aggregate_id,
            aggregate_type: @@type,
            aggregate_version: aggregate_version,
            command_handler: command_handler,
            event_handle: @@handle
          )
          @body = Body.new(comment)
        end
      end
    end
  end
end