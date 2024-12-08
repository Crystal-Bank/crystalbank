module CrystalBank::Domains::ApiKeys
  module Revocation
    module Events
      class Requested < ES::Event
        @@type = "ApiKey"
        @@handle = "api_key.revocation.requested"

        # Data Object for the body of the event
        struct Body < ES::Event::Body
          getter reason : String

          def initialize(
            @comment : String,
            @reason : String
          ); end
        end

        def initialize(@header : ES::Event::Header, body : JSON::Any)
          @body = Body.from_json(body.to_json)
        end

        def initialize(
          actor_id : UUID,
          aggregate_id : UUID,
          aggregate_version : Int32,
          command_handler : String,
          reason : String,
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
          @body = Body.new(
            comment: comment,
            reason: reason
          )
        end
      end
    end
  end
end
