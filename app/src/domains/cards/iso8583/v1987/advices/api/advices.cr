require "./concerns/requests"
require "./concerns/responses"

module CrystalBank::Domains::Cards::Iso8583::V1987::Advices
  module Api
    class AdvicesController
      def process_advice(request : Requests::AdviceRequest, context : CrystalBank::Api::Context)
        context.require_permission!("read_cards_iso8583_v1987_advices")

        raw = Base64.decode(request.raw_message)
        decoder = Shared::Decoder.new(V1987::FIELD_MAP)
        msg = decoder.decode(raw)

        advice_id = Advice::Commands::Process.new.call(
          msg: msg,
          scope_id: request.scope_id,
          actor_id: context.user_id,
          original_authorization_id: request.original_authorization_id,
        )

        Responses::AdviceResponse.new(advice_id: advice_id, status: "pending")
      end

      def list(context : CrystalBank::Api::Context, cursor : Int32, limit : Int32)
        context.require_permission!("read_cards_iso8583_v1987_advices")
        Queries::Advices.new.list(context, cursor, limit)
      end

      def get(id : UUID, context : CrystalBank::Api::Context)
        context.require_permission!("read_cards_iso8583_v1987_advices")
        Queries::Advices.new.get(id, context)
      end
    end
  end
end
