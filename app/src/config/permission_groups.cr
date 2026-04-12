module CrystalBank
  module PermissionGroups
    record PermissionMeta, description : String
    record Group, name : String, description : String, permissions : Hash(Permissions, PermissionMeta)

    @@index : Hash(Permissions, Group)? = nil

    GROUPS = [
      Group.new(
        name: "Accounts",
        description: "Permissions governing account lifecycle: opening, blocking, unblocking, and compliance approvals.",
        permissions: {
          Permissions::READ_accounts_list                         => PermissionMeta.new(description: "List all accounts visible within the caller's scope."),
          Permissions::WRITE_accounts_opening_request             => PermissionMeta.new(description: "Submit a request to open a new account."),
          Permissions::WRITE_accounts_blocking_request            => PermissionMeta.new(description: "Submit a request to place a block on an account."),
          Permissions::WRITE_accounts_unblocking_request          => PermissionMeta.new(description: "Submit a request to lift an existing block from an account."),
          Permissions::WRITE_accounts_blocking_approval           => PermissionMeta.new(description: "Approve or reject a pending account blocking request."),
          Permissions::WRITE_accounts_unblocking_approval         => PermissionMeta.new(description: "Approve or reject a pending account unblocking request."),
          Permissions::READ_accounts_blocks                       => PermissionMeta.new(description: "Read the active and historical blocks on accounts."),
          Permissions::WRITE_accounts_opening_compliance_approval => PermissionMeta.new(description: "Provide compliance sign-off on a pending account opening request."),
          Permissions::WRITE_accounts_opening_board_approval      => PermissionMeta.new(description: "Provide board-level sign-off on a pending account opening request."),
        } of Permissions => PermissionMeta,
      ),
      Group.new(
        name: "API Keys",
        description: "Permissions for generating, approving, and revoking machine-to-machine API credentials.",
        permissions: {
          Permissions::WRITE_api_keys_generation_request  => PermissionMeta.new(description: "Submit a request to generate a new API key."),
          Permissions::WRITE_api_keys_generation_approval => PermissionMeta.new(description: "Approve or reject a pending API key generation request."),
          Permissions::WRITE_api_keys_revocation_request  => PermissionMeta.new(description: "Submit a request to revoke an existing API key."),
          Permissions::READ_api_keys_list                 => PermissionMeta.new(description: "List all API keys visible within the caller's scope."),
        } of Permissions => PermissionMeta,
      ),
      Group.new(
        name: "Customers",
        description: "Permissions for onboarding and querying customer entities.",
        permissions: {
          Permissions::WRITE_customers_onboarding_request => PermissionMeta.new(description: "Submit a request to onboard a new customer."),
          Permissions::READ_customers_list                => PermissionMeta.new(description: "List all customers visible within the caller's scope."),
        } of Permissions => PermissionMeta,
      ),
      Group.new(
        name: "Roles",
        description: "Permissions for creating and querying roles that bundle permissions for assignment to users.",
        permissions: {
          Permissions::READ_roles_list               => PermissionMeta.new(description: "List all roles visible within the caller's scope."),
          Permissions::WRITE_roles_creation_request  => PermissionMeta.new(description: "Submit a request to create a new role."),
          Permissions::WRITE_roles_creation_approval => PermissionMeta.new(description: "Approve or reject a pending role creation request."),
        } of Permissions => PermissionMeta,
      ),
      Group.new(
        name: "Scopes",
        description: "Permissions for creating and querying organizational scopes used in access control.",
        permissions: {
          Permissions::READ_scopes_list               => PermissionMeta.new(description: "List all scopes visible to the caller."),
          Permissions::WRITE_scopes_creation_request  => PermissionMeta.new(description: "Submit a request to create a new scope."),
          Permissions::WRITE_scopes_creation_approval => PermissionMeta.new(description: "Approve or reject a pending scope creation request."),
        } of Permissions => PermissionMeta,
      ),
      Group.new(
        name: "Ledger",
        description: "Permissions for creating ledger entries and reading posting records.",
        permissions: {
          Permissions::WRITE_ledger_transactions_request => PermissionMeta.new(description: "Submit a double-entry ledger transaction request."),
          Permissions::READ_postings_list                => PermissionMeta.new(description: "List ledger posting records visible within the caller's scope."),
        } of Permissions => PermissionMeta,
      ),
      Group.new(
        name: "Transactions",
        description: "Permissions for initiating internal fund transfers between accounts.",
        permissions: {
          Permissions::WRITE_transactions_internal_transfers_initiation_request => PermissionMeta.new(description: "Initiate an internal transfer between two accounts within the platform."),
        } of Permissions => PermissionMeta,
      ),
      Group.new(
        name: "Payments",
        description: "Permissions for requesting, approving, and querying SEPA Credit Transfer payment instructions.",
        permissions: {
          Permissions::WRITE_payments_sepa_credit_transfers_request  => PermissionMeta.new(description: "Submit a SEPA Credit Transfer payment request."),
          Permissions::READ_payments_sepa_credit_transfers_list      => PermissionMeta.new(description: "List SEPA Credit Transfer payment records visible within the caller's scope."),
          Permissions::WRITE_payments_sepa_credit_transfers_approval => PermissionMeta.new(description: "Approve or reject a pending SEPA Credit Transfer payment request."),
        } of Permissions => PermissionMeta,
      ),
      Group.new(
        name: "Users",
        description: "Permissions for onboarding users, assigning roles, and querying user records.",
        permissions: {
          Permissions::WRITE_users_onboarding_request             => PermissionMeta.new(description: "Submit a request to onboard a new platform user."),
          Permissions::WRITE_users_assign_roles_request           => PermissionMeta.new(description: "Submit a request to assign one or more roles to a user."),
          Permissions::READ_users_list                            => PermissionMeta.new(description: "List all users visible within the caller's scope."),
          Permissions::WRITE_users_onboarding_compliance_approval => PermissionMeta.new(description: "Provide compliance sign-off on a pending user onboarding request."),
        } of Permissions => PermissionMeta,
      ),
      Group.new(
        name: "Approvals",
        description: "Permissions for driving the generic approval workflow across all domains.",
        permissions: {
          Permissions::WRITE_approvals_collection_request => PermissionMeta.new(description: "Submit an approval decision on any pending approval item."),
          Permissions::WRITE_approvals_rejection_request  => PermissionMeta.new(description: "Submit a rejection on any pending approval item."),
          Permissions::READ_approvals_list                => PermissionMeta.new(description: "List all approval items visible within the caller's scope."),
        } of Permissions => PermissionMeta,
      ),
      Group.new(
        name: "Events",
        description: "Permissions for reading the raw event stream, intended for audit and debugging.",
        permissions: {
          Permissions::READ_events_list => PermissionMeta.new(description: "Read the event store stream within the caller's scope."),
        } of Permissions => PermissionMeta,
      ),
      Group.new(
        name: "Platform",
        description: "Meta-permissions for querying platform configuration, types, and the caller's own session context.",
        permissions: {
          Permissions::READ_me             => PermissionMeta.new(description: "Read the caller's own user profile and session information."),
          Permissions::READ_platform_types => PermissionMeta.new(description: "Read platform-level type catalogues (account types, currencies, permissions, etc.)."),
        } of Permissions => PermissionMeta,
      ),
    ] of Group

    # Returns the Group that contains the given permission, or nil if not found.
    # The result is memoized after first call: O(n) build once, O(1) lookup thereafter.
    def self.group_for(permission : Permissions) : Group?
      @@index ||= begin
        idx = {} of Permissions => Group
        GROUPS.each { |g| g.permissions.each_key { |p| idx[p] = g } }
        idx
      end
      @@index.not_nil![permission]?
    end

    # Like group_for but raises if the permission has no registered group.
    # Useful in specs to assert full coverage.
    def self.group_for!(permission : Permissions) : Group
      group_for(permission) || raise "No PermissionGroup registered for #{permission}"
    end
  end
end
