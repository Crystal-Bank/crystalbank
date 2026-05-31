module CrystalBank::Domains::Users
  module Projections
    class AssignRolesRequests < ES::Projection
      include ES::ProjectionDSL

      define_projection "projections.user_assign_roles_requests", init: true do
        column :id, UUID, primary_key: true
        column :user_id, UUID, null: false
        column :role_ids, JSON::Any, null: false
        column :completed, Bool, null: false, default: false

        index [:user_id], name: "uarr_user_pending_idx"
      end

      apply(::Users::AssignRoles::Events::Requested) do
        body = event.body.as(::Users::AssignRoles::Events::Requested::Body)
        user_id = body.user_id
        return unless user_id

        @projection_database.exec %(
          INSERT INTO "projections"."user_assign_roles_requests" (id, user_id, role_ids, completed)
          VALUES ($1, $2, $3, false)
          ON CONFLICT (id) DO NOTHING
        ),
          event.header.aggregate_id,
          user_id,
          body.role_ids.to_json
      end

      apply(::Users::AssignRoles::Events::Completed) do
        @projection_database.exec %(
          UPDATE "projections"."user_assign_roles_requests" SET completed = true WHERE id = $1
        ),
          event.header.aggregate_id
      end

      apply(::Users::AssignRoles::Events::Rejected) do
        @projection_database.exec %(
          DELETE FROM "projections"."user_assign_roles_requests" WHERE id = $1
        ),
          event.header.aggregate_id
      end
    end
  end
end
