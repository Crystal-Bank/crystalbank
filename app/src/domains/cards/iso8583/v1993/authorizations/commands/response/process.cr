module CrystalBank::Domains::Cards::Iso8583::V1993::Authorizations
  module Response
    module Commands
      class Process < ES::Command
        APPROVED_CODES = {"00", "08", "10", "85"}

        def call(authorization_id : UUID, msg : Shared::Message, actor_id : UUID) : Nil
          raise ArgumentError.new("Expected MTI 1110, got #{msg.mti}") unless msg.mti == "1110"

          response_code = msg.fields[39]? || raise ArgumentError.new("DE 39 (Response Code) is required")

          if APPROVED_CODES.includes?(response_code)
            auth_code = msg.fields[38]? || ""
            event = V1993::Authorizations::Response::Events::Approved.new(
              aggregate_id: authorization_id,
              actor_id: actor_id,
              command_handler: self.class.to_s,
              auth_code: auth_code,
              response_code: response_code,
            )
          else
            event = V1993::Authorizations::Response::Events::Declined.new(
              aggregate_id: authorization_id,
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
