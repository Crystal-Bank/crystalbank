module CrystalBank::Domains::ApiKeys
  module Generation
    module Events
      class Requested < ES::Event
        @@type = "ApiKey"
        @@handle = "api_key.generation.requested"

        # Data Object for the body of the event
        struct Body < ES::Event::Body
          getter name : String
          getter user_id : UUID
          getter api_secret : String

          def initialize(
            @api_secret : String,
            @comment : String,
            @name : String,
            @user_id : UUID
          ); end
        end

        def initialize(@header : ES::Event::Header, body : JSON::Any)
          @body = Body.from_json(body.to_json)
        end

        def initialize(
          actor_id : UUID,
          api_secret : String,
          command_handler : String,
          name : String,
          user_id : UUID,
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
            api_secret: api_secret,
            comment: comment,
            name: name,
            user_id: user_id
          )
        end
      end
    end
  end
end
