module CrystalBank::Domains::Customers
  module Onboarding
    module Events
      class Requested < ES::Event
        @@type = "Customer"
        @@handle = "customer.onboarding.requested"

        # Data Object for the body of the event
        struct Body < ES::Event::Body
          getter name : String
          getter scope_id : UUID
          getter type : CrystalBank::Types::Customers::Type

          def initialize(
            @comment : String,
            @name : String,
            @scope_id : UUID,
            @type : CrystalBank::Types::Customers::Type,
          ); end
        end

        def initialize(@header : ES::Event::Header, body : JSON::Any)
          @body = Body.from_json(body.to_json)
        end

        def initialize(
          actor_id : UUID,
          command_handler : String,
          name : String,
          scope_id : UUID,
          type : CrystalBank::Types::Customers::Type,
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
            scope_id: scope_id,
            type: type
          )
        end
      end
    end
  end
end
