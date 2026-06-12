module CrystalBank::Domains::Cards::Iso8583::V1993::Authorizations
  module Request
    module Commands
      class Process < ES::Command
        def call(msg : Shared::Message, scope_id : UUID, actor_id : UUID) : UUID
          raise ArgumentError.new("Expected MTI 1100, got #{msg.mti}") unless msg.mti == "1100"

          stan        = msg.fields[11]? || raise ArgumentError.new("DE 11 (STAN) is required")
          pan         = msg.fields[2]?  || raise ArgumentError.new("DE 2 (PAN) is required")
          amount_str  = msg.fields[4]?  || raise ArgumentError.new("DE 4 (Amount) is required")
          currency    = msg.fields[49]? || raise ArgumentError.new("DE 49 (Currency) is required")
          terminal_id = msg.fields[41]? || raise ArgumentError.new("DE 41 (Terminal ID) is required")
          merchant_id = msg.fields[42]? || raise ArgumentError.new("DE 42 (Merchant ID) is required")

          event = V1993::Authorizations::Request::Events::Received.new(
            actor_id: actor_id,
            command_handler: self.class.to_s,
            stan: stan,
            pan_masked: mask_pan(pan),
            amount: amount_str.to_i64,
            currency: currency,
            terminal_id: terminal_id,
            merchant_id: merchant_id,
            account_id_1: msg.fields[102]?,
            account_id_2: msg.fields[103]?,
            scope_id: scope_id,
            raw_mti: msg.mti,
          )

          @event_store.append(event)
          UUID.new(event.header.aggregate_id.to_s)
        end

        private def mask_pan(pan : String) : String
          return pan if pan.size < 10
          pan[0, 6] + "*" * (pan.size - 10) + pan[-4..]
        end
      end
    end
  end
end
