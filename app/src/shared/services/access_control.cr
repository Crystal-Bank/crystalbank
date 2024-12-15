# TODO: Adjust
# 
module CrystalBank
  module Services
    class AccessControl
      getter roles : Array(UUID)

      def initialize(@roles : Array(UUID),
                     @projection_db : DB::Database = ES::Config.projection_db,
                     @event_store : ES::EventStore = ES::Config.event_store,
                     @event_handlers : ES::EventHandlers = ES::Config.event_handlers)
      end

      def available_permissions(scope_id : UUID) : Array(String)
        available_permissions = [] of String
        # TODO: This could be done with a public interface instead of a reuse of the query
        scope_parents_tree = Scopes::Queries::ScopesTreeForAuthorization.new(projection_db: @projection_db).fetch_all_parents(scope_id).push(scope_id)

        @roles.each do |role_id|
          # TODO: Switch to projection for performance reasons
          role_aggregate = CrystalBank::Domains::Roles::Aggregate.new(role_id, event_store: @event_store, event_handlers: @event_handlers)
          role_aggregate.hydrate

          # Fetch permissions from the role
          role_permissions = role_aggregate.state.permissions

          # Collect all permissions of the scope and parent scopes from the role
          available_permissions.concat(
            scope_parents_tree.map do |s_id|
              role_permissions.fetch(s_id, [] of String)
            end.flatten
          )
        end

        available_permissions.uniq
      end

      def available_scopes(required_permission : String) : Array(UUID)
        accessible_scopes = [] of UUID

        @roles.each do |role_id|
          role_aggregate = CrystalBank::Domains::Roles::Aggregate.new(role_id, event_store: @event_store, event_handlers: @event_handlers)
          role_aggregate.hydrate

          puts role_aggregate.state.inspect

          role_permissioned_scopes = role_aggregate.state.permissions.map do |scope, permissions|
            puts "- -"
            puts permissions
            puts "- -"
            permissions.includes?(required_permission) ? scope : nil
          end.compact

          accessible_scopes.concat(role_permissioned_scopes)
        end

        all_child_scopes = accessible_scopes.compact.map do |scope_id|
          # TODO: This could be done with a public interface instead of a reuse of the query
          Scopes::Queries::ScopesTreeForAuthorization.new(projection_db: @projection_db).fetch_all_childs(scope_id)
        end.flatten

        accessible_scopes.concat(all_child_scopes).compact
      end
    end
  end
end

private def fetch_available_scopes(required_permission : String, projection_db : DB::Database, event_store : ES::EventStore, event_handlers : ES::EventHandlers, required_scope : UUID? = nil) : Array(UUID)
  available_scopes = [] of UUID

  # TODO: Switch to projection of roles to speed up the process
  @roles.each do |role_id|
    role_aggregate = CrystalBank::Domains::Roles::Aggregate.new(role_id, event_store: event_store, event_handlers: event_handlers)
    role_aggregate.hydrate

    # Filter out permissions that are not explicitly requested (NOT WORKING AT THE MOMENT!!!)
    # TODO: This does not properly filter out if the scope is not exlicitly defined in the role
    relevant_permissions = role_aggregate.state.permissions.reject { |key, value| !required_scope.nil? && key != required_scope }

    # Map all scopes that have the requested permission
    role_permissioned_scopes = relevant_permissions.map do |scope, permissions|
      permissions.includes?(required_permission) ? scope : nil
    end.compact

    available_scopes.concat(role_permissioned_scopes)
  end

  all_child_scopes = available_scopes.compact.map do |scope_id|
    # TODO: This could be done with a public interface instead of a reuse of the query
    Scopes::Queries::ScopesTreeForAuthorization.new(projection_db: projection_db).fetch_all_childs(scope_id)
  end.flatten

  available_scopes.concat(all_child_scopes).compact
end
