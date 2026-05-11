module CrystalBank::Domains::ApiKeys
  module Generation
    module Commands
      class ProcessRequest < ES::Command
        def call
          aggregate_id = @aggregate_id.as(UUID)

          # Build the api key aggregate
          aggregate = ApiKeys::Aggregate.new(aggregate_id)
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
          Approvals::Creation::Commands::Request.new.call(
            source_aggregate_type: "ApiKey",
            source_aggregate_id: aggregate_id,
            scope_id: scope_id,
            required_approvals: [
              "write_api_keys_generation_approval",
            ],
            actor_id: aggregate.state.requestor_id,
            subject: approval_subject,
          )
        end
      end
    end
  end
end
