module CrystalBank
  enum Permissions
    # Accounts
    READ_accounts_list
    WRITE_accounts_opening_request

    # Api Keys
    WRITE_api_keys_generation_request
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

    # Transactions -> Internal Transfers
    WRITE_transactions_internal_transfers_initiation_request

    # Transactions -> Postings
    READ_postings_list

    # Users
    WRITE_users_onboarding_request
    WRITE_users_assign_roles_request
    READ_users_list

    def to_s
      super.to_s.downcase
    end
  end
end
