module CrystalBank::Domains::Users
  module Projections
    class AssignRolesRequests < ES::Projection
      def prepare
        skip = @projection_database.query_one %(SELECT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'projections' AND tablename = 'user_assign_roles_requests');), as: Bool
        return true if skip

        m = Array(String).new
        m << %(
          CREATE TABLE "projections"."user_assign_roles_requests" (
            "id" UUID PRIMARY KEY,
            "user_id" UUID NOT NULL,
            "role_ids" JSONB NOT NULL,
            "completed" boolean NOT NULL DEFAULT false
          );
        )
        m << %(CREATE INDEX uarr_user_pending_idx ON "projections"."user_assign_roles_requests"(user_id) WHERE NOT completed;)
        m.each { |s| @projection_database.exec s }
      end

      def apply(event : ::Users::AssignRoles::Events::Requested)
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

      def apply(event : ::Users::AssignRoles::Events::Completed)
        @projection_database.exec %(
          UPDATE "projections"."user_assign_roles_requests" SET completed = true WHERE id = $1
        ),
          event.header.aggregate_id
      end
    end
  end
end
