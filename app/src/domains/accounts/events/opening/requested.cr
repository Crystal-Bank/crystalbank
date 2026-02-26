module CrystalBank::Domains::Accounts
  module Opening
    module Events
      class Requested < ES::Event
        @@type = "Account"
        @@handle = "account.opening.requested"

        macro event_field(name, type)
          # consumed by `define_event`
        end

        macro define_event(&block)
          {% entries = block.body.is_a?(Expressions) ? block.body.expressions : [block.body] %}

          # Data Object for the body of the event
          struct Body < ES::Event::Body
            {% for entry in entries %}
              getter {{ entry.args[0].id }} : {{ entry.args[1] }}
            {% end %}

            def initialize(
              @comment : String,
              {% for entry in entries %}
                @{{ entry.args[0].id }} : {{ entry.args[1] }},
              {% end %}
            ); end
          end

          def initialize(
            actor_id : UUID,
            command_handler : String,
            {% for entry in entries %}
              {{ entry.args[0].id }} : {{ entry.args[1] }},
            {% end %}
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
              {% for entry in entries %}
                {{ entry.args[0].id }}: {{ entry.args[0].id }},
              {% end %}
            )
          end
        end

        define_event do
          event_field :currencies, Array(CrystalBank::Types::Currencies::Supported)
          event_field :customer_ids, Array(UUID)
          event_field :scope_id, UUID
          event_field :type, CrystalBank::Types::Accounts::Type
        end

        def initialize(@header : ES::Event::Header, body : JSON::Any)
          @body = Body.from_json(body.to_json)
        end
      end
    end
  end
end
