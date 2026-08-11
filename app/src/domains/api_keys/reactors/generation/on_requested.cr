module CrystalBank::Domains::ApiKeys
  module Reactors
    module Generation
      class OnRequested < ES::Reactor
        def call(event : ApiKeys::Generation::Events::Requested)
          aggregate_id = event.header.aggregate_id

          # Build the api key aggregate
          aggregate = ApiKeys::Aggregate.new(aggregate_id, event_store: @event_store, event_handlers: @event_handlers)
          aggregate.hydrate

          scope_id = aggregate.state.scope_id.as(UUID)

          key_name = aggregate.state.name || "unknown"
          user_label = if (uid = aggregate.state.user_id)
                         user = Users::Queries::Users.new.get(uid)
                         if user
                           "#{user.name} <#{user.email}>"
                         else
                           uid.to_s
                         end
                       else
                         "unknown"
                       end
          approval_subject = Approvals::ApprovalSubject.new(
            title: "API Key Generation",
            summary: key_name,
            fields: [
              Approvals::ApprovalSubject::Field.new("Name", key_name),
              Approvals::ApprovalSubject::Field.new("User", user_label),
              Approvals::ApprovalSubject::Field.new("Key ID", aggregate_id.to_s),
            ] of Approvals::ApprovalSubject::Field
          )

          # Create an approval workflow for this api key generation
          Approvals::Creation::Commands::RequestHandler.new(event_store: @event_store, event_handlers: @event_handlers).handle(
            Approvals::Creation::Commands::Request.new(
              aggregate_id: UUID.v7,
              source_aggregate_type: "ApiKey",
              source_aggregate_id: aggregate_id,
              scope_id: scope_id,
              required_approvals: [
                "write_api_keys_generation_approval",
              ],
              actor_id: aggregate.state.requestor_id,
              subject: approval_subject,
            )
          )
        end
      end
    end
  end
end
