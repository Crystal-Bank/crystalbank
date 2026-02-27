module CrystalBank::Shared::Events
  module RequestedEventDSL
    macro event_field(name, type)
      # consumed by `define_requested_event`
    end

    macro define_requested_event(event_type, event_handle, &block)
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
  end
end
