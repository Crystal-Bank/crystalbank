module CrystalBank
  enum Permissions
    # Accounts
    READ_accounts_list
    WRITE_accounts_opening_request
    WRITE_accounts_blocking_request
    WRITE_accounts_unblocking_request
    WRITE_accounts_blocking_approval
    WRITE_accounts_unblocking_approval
    READ_accounts_blocks

    # Api Keys
    WRITE_api_keys_generation_request
    WRITE_api_keys_generation_approval
    WRITE_api_keys_revocation_request
    READ_api_keys_list

    # Customers
    WRITE_customers_onboarding_request
    READ_customers_list

    # Roles
    READ_roles_list
    WRITE_roles_creation_request

    # Scopes
    READ_scopes_list
    WRITE_scopes_creation_request
    WRITE_scopes_creation_approval

    # Ledger -> Transactions
    WRITE_ledger_transactions_request

    # Transactions -> Internal Transfers
    WRITE_transactions_internal_transfers_initiation_request

    # Transactions -> Postings
    READ_postings_list

    # Users
    WRITE_users_onboarding_request
    WRITE_users_assign_roles_request
    READ_users_list

    # Approvals
    WRITE_approvals_collection_request
    WRITE_approvals_rejection_request
    READ_approvals_list

    # Account Opening Approvals
    WRITE_accounts_opening_compliance_approval
    WRITE_accounts_opening_board_approval

    # User Onboarding Approvals
    WRITE_users_onboarding_compliance_approval

    # Payments — SEPA Credit Transfers
    WRITE_payments_sepa_credit_transfers_request
    READ_payments_sepa_credit_transfers_list
    WRITE_payments_sepa_credit_transfers_approval

    # Events
    READ_events_list

    # Me
    READ_me

    def to_s
      super.to_s.downcase
    end
  end
end
