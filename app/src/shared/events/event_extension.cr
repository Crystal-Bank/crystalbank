module ES
  module EventDSL
    macro event_field(name, type)
      # consumed by `define_event`
    end

    macro define_event(event_type, event_handle, &block)
      @@type = {{ event_type }}
      @@handle = {{ event_handle }}

      {% entries = block.body.is_a?(Expressions) ? block.body.expressions : [block.body] %}

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

      def initialize(@header : ES::Event::Header, body : JSON::Any)
        @body = Body.from_json(body.to_json)
      end

      def initialize(
        actor_id : UUID,
        command_handler : String,
        {% for entry in entries %}
          {{ entry.args[0].id }} : {{ entry.args[1] }},
        {% end %}
        comment = "",
        aggregate_id = UUID.v7,
        aggregate_version : Int32 = 1,
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
          {% for entry in entries %}
            {{ entry.args[0].id }}: {{ entry.args[0].id }},
          {% end %}
        )
      end
    end
  end

  abstract class EventExtension < ES::Event
    macro inherited
      extend ::ES::EventDSL
    end

    extend EventDSL
  end
end
