module CrystalBank::Domains::Accounts
  module Opening
    module Events
      class Requested < ES::Event
        @@type = "Account"
        @@handle = "account.opening.requested"

        # Data Object for the body of the event
        struct Body < ES::Event::Body
          getter currencies : Array(CrystalBank::Types::Currencies::Supported)
          getter type : CrystalBank::Types::Accounts::Type

          def initialize(
            @comment : String,
            @currencies : Array(CrystalBank::Types::Currencies::Supported),
            @type : CrystalBank::Types::Accounts::Type
          ); end
        end

        def initialize(@header : ES::Event::Header, body : JSON::Any)
          @body = Body.from_json(body.to_json)
        end

        def initialize(
          actor_id : UUID,
          command_handler : String,
          currencies : Array(CrystalBank::Types::Currencies::Supported),
          type : CrystalBank::Types::Accounts::Type,
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
            currencies: currencies,
            type: type
          )
        end
      end
    end
  end
end
