module CrystalBank
  module PermissionsDSL
    # Generates both `CrystalBank::Permissions` (enum) and `CrystalBank::PermissionGroups`
    # (GROUPS constant + group_for helpers) from a single call-site definition.
    #
    # Usage: include ::CrystalBank::PermissionsDSL in a module, then call
    # define_permissions(...) directly. See permissions.cr.
    macro define_permissions(*group_defs)
      enum Permissions
        {% for group_def in group_defs %}
          {% for perm in group_def[:permissions] %}
            {{perm[:key].id}}
          {% end %}
        {% end %}

        def to_s
          super.to_s.downcase
        end
      end

      module PermissionGroups
        record PermissionMeta, description : String
        record Group,
          name : String,
          description : String,
          permissions : Hash(Permissions, PermissionMeta)

        @@index : Hash(Permissions, Group)? = nil

        GROUPS = [
          {% for group_def in group_defs %}
            Group.new(
              name: {{group_def[:group]}},
              description: {{group_def[:description]}},
              permissions: {
                {% for perm in group_def[:permissions] %}
                  Permissions::{{perm[:key].id}} => PermissionMeta.new(description: {{perm[:description]}}),
                {% end %}
              } of Permissions => PermissionMeta,
            ),
          {% end %}
        ] of Group

        # Returns the Group containing the given permission, or nil.
        # Memoized: O(n) build once, O(1) lookup thereafter.
        def self.group_for(permission : Permissions) : Group?
          @@index ||= begin
            idx = {} of Permissions => Group
            GROUPS.each { |g| g.permissions.each_key { |p| idx[p] = g } }
            idx
          end
          @@index.not_nil![permission]?
        end

        # Like group_for but raises if the permission has no registered group.
        def self.group_for!(permission : Permissions) : Group
          group_for(permission) || raise "No PermissionGroup registered for #{permission}"
        end
      end
    end
  end
end
