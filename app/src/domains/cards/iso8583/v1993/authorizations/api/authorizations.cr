require "./concerns/requests"
require "./concerns/responses"

module CrystalBank::Domains::Cards::Iso8583::V1993::Authorizations
  module Api
    class AuthorizationsController
      def process_request(request : Requests::AuthorizationRequest, context : CrystalBank::Api::Context)
        context.require_permission!("read_cards_iso8583_v1993_authorizations")

        raw = Base64.decode(request.raw_message)
        decoder = Shared::Decoder.new(V1993::FIELD_MAP)
        msg = decoder.decode(raw)

        authorization_id = Request::Commands::Process.new.call(
          msg: msg,
          scope_id: request.scope_id,
          actor_id: context.user_id,
        )

        Responses::AuthorizationResponse.new(
          authorization_id: authorization_id,
          status: "pending",
        )
      end

      def list(context : CrystalBank::Api::Context, cursor : Int32, limit : Int32)
        context.require_permission!("read_cards_iso8583_v1993_authorizations")
        Queries::Authorizations.new.list(context, cursor, limit)
      end

      def get(id : UUID, context : CrystalBank::Api::Context)
        context.require_permission!("read_cards_iso8583_v1993_authorizations")
        Queries::Authorizations.new.get(id, context)
      end
    end
  end
end
