module CrystalBank::Domains::Cards::Iso8583::V1993::Advices
  module AdviceResponse
    module Commands
      class Process < ES::Command
        ACCEPTED_CODES = {"00", "10"}

        def call(advice_id : UUID, msg : Shared::Message, actor_id : UUID) : Nil
          raise ArgumentError.new("Expected MTI 1130, got #{msg.mti}") unless msg.mti == "1130"

          response_code = msg.fields[39]? || raise ArgumentError.new("DE 39 (Response Code) is required")

          if ACCEPTED_CODES.includes?(response_code)
            event = V1993::Advices::AdviceResponse::Events::Accepted.new(
              aggregate_id: advice_id,
              actor_id: actor_id,
              command_handler: self.class.to_s,
              response_code: response_code,
            )
          else
            event = V1993::Advices::AdviceResponse::Events::Rejected.new(
              aggregate_id: advice_id,
              actor_id: actor_id,
              command_handler: self.class.to_s,
              response_code: response_code,
              reason: nil,
            )
          end

          @event_store.append(event)
        end
      end
    end
  end
end
