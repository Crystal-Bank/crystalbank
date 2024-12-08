module CrystalBank::Domains::ApiKeys
  module Revocation
    module Events
      class Accepted < ES::Event
        @@type = "ApiKey"
        @@handle = "api_key.revocation.accepted"

        # Data Object for the body of the event
        struct Body < ES::Event::Body
          def initialize(@comment); end
        end

        def initialize(@header : ES::Event::Header, body : JSON::Any)
          @body = Body.from_json(body.to_json)
        end

        def initialize(
          aggregate_id : UUID,
          aggregate_version : Int32,
          command_handler : String,
          actor_id : UUID?,
          comment = ""
        )
          @header = Header.new(
            actor_id: actor_id,
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
