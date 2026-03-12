// Global reactive state (Svelte 5 runes)
// Imported and mutated directly by components and action functions.

export const auth = $state({
  token: localStorage.getItem('cb_token') || '',
  scope: localStorage.getItem('cb_scope') || '',
  scopeInput: localStorage.getItem('cb_scope') || '',
})

export const ui = $state({
  view: 'accounts',
  loading: false,
  loadingView: /** @type {string|null} */ (null),
  /** @type {Array<{id: number, msg: string, type: string}>} */
  toasts: [],
})

export const viewData = $state({
  accounts: [],
  customers: [],
  postings: [],
  users: [],
  roles: [],
  scopes: [],
  api_keys: [],
  approvals: [],
})

export const pagination = $state({
  hasMore: {
    accounts: false,
    customers: false,
    postings: false,
    users: false,
    roles: false,
    scopes: false,
    api_keys: false,
    approvals: false,
  },
  cursors: {
    accounts: null,
    customers: null,
    postings: null,
    users: null,
    roles: null,
    scopes: null,
    api_keys: null,
    approvals: null,
  },
})

export const SUPPORTED_CURRENCIES = ['chf', 'eur', 'gbp', 'jpy', 'usd']

export const ALL_PERMISSIONS = [
  'read_accounts_list',
  'write_accounts_opening_request',
  'write_accounts_opening_compliance_approval',
  'write_accounts_opening_board_approval',
  'read_api_keys_list',
  'write_api_keys_generation_request',
  'write_api_keys_revocation_request',
  'read_customers_list',
  'write_customers_onboarding_request',
  'read_roles_list',
  'write_roles_creation_request',
  'read_scopes_list',
  'write_scopes_creation_request',
  'read_postings_list',
  'write_transactions_internal_transfers_initiation_request',
  'read_users_list',
  'write_users_onboarding_request',
  'write_users_assign_roles_request',
  'read_approvals_list',
  'write_approvals_collection_request',
]

export const NAV_SECTIONS = [
  {
    label: 'Compliance',
    items: [
      {
        id: 'approvals',
        label: 'Approvals',
        icon: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>`,
      },
    ],
  },
  {
    label: 'Operations',
    items: [
      {
        id: 'customers',
        label: 'Customers',
        icon: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 00-3-3.87M16 3.13a4 4 0 010 7.75"/></svg>`,
      },
      {
        id: 'accounts',
        label: 'Accounts',
        icon: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="7" width="20" height="14" rx="2"/><path d="M16 7V5a2 2 0 00-2-2h-4a2 2 0 00-2 2v2"/></svg>`,
      },
      {
        id: 'postings',
        label: 'Transactions',
        icon: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="12" y1="1" x2="12" y2="23"/><path d="M17 5H9.5a3.5 3.5 0 000 7h5a3.5 3.5 0 010 7H6"/></svg>`,
      },
    ],
  },
  {
    label: 'Management',
    items: [
      {
        id: 'users',
        label: 'Users',
        icon: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M20 21v-2a4 4 0 00-4-4H8a4 4 0 00-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>`,
      },
      {
        id: 'roles',
        label: 'Roles',
        icon: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>`,
      },
      {
        id: 'scopes',
        label: 'Scopes',
        icon: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><line x1="2" y1="12" x2="22" y2="12"/><path d="M12 2a15.3 15.3 0 010 20M12 2a15.3 15.3 0 000 20"/></svg>`,
      },
      {
        id: 'api_keys',
        label: 'API Keys',
        icon: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 2l-2 2m-7.61 7.61a5.5 5.5 0 11-7.778 7.778 5.5 5.5 0 017.777-7.777zm0 0L15.5 7.5m0 0l3 3L22 7l-3-3m-3.5 3.5L19 4"/></svg>`,
      },
    ],
  },
]

export const VIEW_PATHS = {
  accounts:  '/accounts/',
  customers: '/customers/',
  postings:  '/ledger/transactions/postings/',
  users:     '/users/',
  roles:     '/roles/',
  scopes:    '/scopes/',
  api_keys:  '/api_keys/',
  approvals: '/approvals/',
}
