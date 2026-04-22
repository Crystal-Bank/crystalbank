module CrystalBank
  include ::CrystalBank::PermissionsDSL

  define_permissions(
    {
      group:       "Accounts",
      description: "Permissions governing account lifecycle: opening, blocking, unblocking, and compliance approvals.",
      permissions: [
        {key: "READ_accounts_list", description: "List all accounts visible within the caller's scope."},
        {key: "WRITE_accounts_opening_request", description: "Submit a request to open a new account."},
        {key: "WRITE_accounts_blocking_request", description: "Submit a request to place a block on an account."},
        {key: "WRITE_accounts_unblocking_request", description: "Submit a request to lift an existing block from an account."},
        {key: "WRITE_accounts_blocking_approval", description: "Approve or reject a pending account blocking request."},
        {key: "WRITE_accounts_unblocking_approval", description: "Approve or reject a pending account unblocking request."},
        {key: "READ_accounts_blocks", description: "Read the active and historical blocks on accounts."},
        {key: "WRITE_accounts_opening_compliance_approval", description: "Provide compliance sign-off on a pending account opening request."},
        {key: "WRITE_accounts_opening_board_approval", description: "Provide board-level sign-off on a pending account opening request."},
      ],
    },
    {
      group:       "API Keys",
      description: "Permissions for generating, approving, and revoking machine-to-machine API credentials.",
      permissions: [
        {key: "WRITE_api_keys_generation_request", description: "Submit a request to generate a new API key."},
        {key: "WRITE_api_keys_generation_approval", description: "Approve or reject a pending API key generation request."},
        {key: "WRITE_api_keys_revocation_request", description: "Submit a request to revoke an existing API key."},
        {key: "READ_api_keys_list", description: "List all API keys visible within the caller's scope."},
      ],
    },
    {
      group:       "Customers",
      description: "Permissions for onboarding and querying customer entities.",
      permissions: [
        {key: "WRITE_customers_onboarding_request", description: "Submit a request to onboard a new customer."},
        {key: "WRITE_customers_onboarding_compliance_approval", description: "Provide compliance sign-off on a pending customer onboarding request."},
        {key: "READ_customers_list", description: "List all customers visible within the caller's scope."},
      ],
    },
    {
      group:       "Roles",
      description: "Permissions for creating, updating, and querying roles that bundle permissions for assignment to users.",
      permissions: [
        {key: "READ_roles_list", description: "List all roles visible within the caller's scope."},
        {key: "WRITE_roles_creation_request", description: "Submit a request to create a new role."},
        {key: "WRITE_roles_creation_approval", description: "Approve or reject a pending role creation request."},
        {key: "WRITE_roles_permissions_update_request", description: "Submit a request to add or remove permissions on an existing role."},
        {key: "WRITE_roles_permissions_update_approval", description: "Approve or reject a pending role permissions update request."},
      ],
    },
    {
      group:       "Scopes",
      description: "Permissions for creating and querying organizational scopes used in access control.",
      permissions: [
        {key: "READ_scopes_list", description: "List all scopes visible to the caller."},
        {key: "WRITE_scopes_creation_request", description: "Submit a request to create a new scope."},
        {key: "WRITE_scopes_creation_approval", description: "Approve or reject a pending scope creation request."},
      ],
    },
    {
      group:       "Ledger",
      description: "Permissions for creating ledger entries and reading posting records.",
      permissions: [
        {key: "WRITE_ledger_transactions_request", description: "Submit a double-entry ledger transaction request."},
        {key: "READ_postings_list", description: "List ledger posting records visible within the caller's scope."},
      ],
    },
    {
      group:       "Transactions",
      description: "Permissions for initiating internal fund transfers between accounts.",
      permissions: [
        {key: "WRITE_transactions_internal_transfers_initiation_request", description: "Initiate an internal transfer between two accounts within the platform."},
      ],
    },
    {
      group:       "Payments",
      description: "Permissions for requesting, approving, and querying SEPA Credit Transfer payment instructions.",
      permissions: [
        {key: "WRITE_payments_sepa_credit_transfers_request", description: "Submit a SEPA Credit Transfer payment request."},
        {key: "READ_payments_sepa_credit_transfers_list", description: "List SEPA Credit Transfer payment records visible within the caller's scope."},
        {key: "WRITE_payments_sepa_credit_transfers_approval", description: "Approve or reject a pending SEPA Credit Transfer payment request."},
      ],
    },
    {
      group:       "Users",
      description: "Permissions for onboarding users, assigning roles, and querying user records.",
      permissions: [
        {key: "WRITE_users_onboarding_request", description: "Submit a request to onboard a new platform user."},
        {key: "WRITE_users_assign_roles_request", description: "Submit a request to assign one or more roles to a user."},
        {key: "WRITE_users_remove_roles_request", description: "Submit a request to remove one or more roles from a user."},
        {key: "READ_users_list", description: "List all users visible within the caller's scope."},
        {key: "WRITE_users_onboarding_compliance_approval", description: "Provide compliance sign-off on a pending user onboarding request."},
      ],
    },
    {
      group:       "Approvals",
      description: "Permissions for driving the generic approval workflow across all domains.",
      permissions: [
        {key: "WRITE_approvals_collection_request", description: "Submit an approval decision on any pending approval item."},
        {key: "WRITE_approvals_rejection_request", description: "Submit a rejection on any pending approval item."},
        {key: "READ_approvals_list", description: "List all approval items visible within the caller's scope."},
      ],
    },
    {
      group:       "Events",
      description: "Permissions for reading the raw event stream, intended for audit and debugging.",
      permissions: [
        {key: "READ_events_list", description: "Read the event store stream within the caller's scope."},
      ],
    },
    {
      group:       "Platform",
      description: "Meta-permissions for querying platform configuration, types, and the caller's own session context.",
      permissions: [
        {key: "READ_me", description: "Read the caller's own user profile and session information."},
        {key: "READ_platform_types", description: "Read platform-level type catalogues (account types, currencies, permissions, etc.)."},
      ],
    },
  )
end
