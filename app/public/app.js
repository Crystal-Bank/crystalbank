function crystalBank() {
  return {
    // ── Auth state ────────────────────────────────────────
    token: localStorage.getItem('cb_token') || '',
    scope: localStorage.getItem('cb_scope') || '',
    scopeInput: localStorage.getItem('cb_scope') || '',

    // ── Login form ────────────────────────────────────────
    loginForm: { clientId: '', clientSecret: '' },
    loginError: '',

    // ── UI state ──────────────────────────────────────────
    view: 'accounts',
    loading: false,
    toasts: [],
    modal: null,
    modalForm: {},

    // ── Data per view ─────────────────────────────────────
    data: {
      accounts: [], customers: [], postings: [],
      users: [], roles: [], scopes: [], api_keys: []
    },
    hasMore: {
      accounts: false, customers: false, postings: false,
      users: false, roles: false, scopes: false, api_keys: false
    },
    cursors: {
      accounts: null, customers: null, postings: null,
      users: null, roles: null, scopes: null, api_keys: null
    },

    // ── Static data ───────────────────────────────────────
    supportedCurrencies: ['chf', 'eur', 'gbp', 'jpy', 'usd'],

    allPermissions: [
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
    ],

    navItems: [
      {
        id: 'accounts', label: 'Accounts',
        icon: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="7" width="20" height="14" rx="2"/><path d="M16 7V5a2 2 0 00-2-2h-4a2 2 0 00-2 2v2"/></svg>'
      },
      {
        id: 'customers', label: 'Customers',
        icon: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 00-3-3.87M16 3.13a4 4 0 010 7.75"/></svg>'
      },
      {
        id: 'postings', label: 'Transactions',
        icon: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="12" y1="1" x2="12" y2="23"/><path d="M17 5H9.5a3.5 3.5 0 000 7h5a3.5 3.5 0 010 7H6"/></svg>'
      },
      {
        id: 'users', label: 'Users',
        icon: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M20 21v-2a4 4 0 00-4-4H8a4 4 0 00-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>'
      },
      {
        id: 'roles', label: 'Roles',
        icon: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>'
      },
      {
        id: 'scopes', label: 'Scopes',
        icon: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><line x1="2" y1="12" x2="22" y2="12"/><path d="M12 2a15.3 15.3 0 010 20M12 2a15.3 15.3 0 000 20"/></svg>'
      },
      {
        id: 'api_keys', label: 'API Keys',
        icon: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 2l-2 2m-7.61 7.61a5.5 5.5 0 11-7.778 7.778 5.5 5.5 0 017.777-7.777zm0 0L15.5 7.5m0 0l3 3L22 7l-3-3m-3.5 3.5L19 4"/></svg>'
      },
    ],

    viewPaths: {
      accounts:  '/accounts/',
      customers: '/customers/',
      postings:  '/transactions/postings/',
      users:     '/users/',
      roles:     '/roles/',
      scopes:    '/scopes/',
      api_keys:  '/api_keys/',
    },

    // ── Lifecycle ─────────────────────────────────────────
    init() {
      if (this.token) this.loadView('accounts')
    },

    // ── Auth ──────────────────────────────────────────────
    async login() {
      this.loginError = ''
      this.loading = true
      try {
        const res = await fetch('/oauth/token', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            grant_type: 'client_credentials',
            client_id: this.loginForm.clientId,
            client_secret: this.loginForm.clientSecret,
          }),
        })
        if (!res.ok) {
          const err = await res.json().catch(() => ({}))
          this.loginError = err.message || 'Authentication failed'
          return
        }
        const body = await res.json()
        this.token = body.token
        localStorage.setItem('cb_token', this.token)
        this.loadView('accounts')
      } catch (e) {
        this.loginError = 'Connection error: ' + (e.message || e)
      } finally {
        this.loading = false
      }
    },

    logout() {
      this.token = ''
      localStorage.removeItem('cb_token')
    },

    setScope(value) {
      this.scope = value
      if (value) localStorage.setItem('cb_scope', value)
      else localStorage.removeItem('cb_scope')
    },

    // ── Navigation ────────────────────────────────────────
    switchView(id) {
      if (this.view === id && this.data[id].length > 0) return
      this.loadView(id)
    },

    // ── Data loading ──────────────────────────────────────
    async loadView(id) {
      this.view = id
      this.data[id] = []
      this.cursors[id] = null
      this.hasMore[id] = false
      await this.loadMore(id)
    },

    async loadMore(id) {
      if (this.loading) return
      this.loading = true
      try {
        let url = this.viewPaths[id] + '?limit=20'
        if (this.cursors[id]) url += '&cursor=' + this.cursors[id]
        const res = await this.apiFetch('GET', url)
        const items = res.data.map(e => e.attributes)
        this.data[id] = [...(this.data[id] || []), ...items]
        this.hasMore[id] = res.meta.has_more
        this.cursors[id] = res.meta.next_cursor || null
      } catch (e) {
        this.toast(e.message, 'error')
      } finally {
        this.loading = false
      }
    },

    // ── API helper ────────────────────────────────────────
    async apiFetch(method, path, body = null, opts = {}) {
      const headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ' + this.token,
      }
      if (opts.scope !== false && this.scope) headers['X-Scope'] = this.scope
      if (opts.idempotency) headers['idempotency_key'] = crypto.randomUUID()
      const res = await fetch(path, {
        method,
        headers,
        body: body ? JSON.stringify(body) : null,
      })
      if (!res.ok) {
        let msg = 'Request failed (' + res.status + ')'
        try { const e = await res.json(); msg = e.message || msg } catch {}
        throw new Error(msg)
      }
      if (res.status === 204 || res.headers.get('Content-Length') === '0') return {}
      return res.json()
    },

    // ── Modal ─────────────────────────────────────────────
    openModal(type) {
      this.modal = type
      this.modalForm = {
        // arrays managed explicitly to avoid Alpine x-for/x-model reactivity issues
        selectedCurrencies: [],
        selectedPermissions: [],
      }
    },

    closeModal() {
      this.modal = null
      this.modalForm = {}
    },

    // Checkbox helpers — explicit array mutation avoids x-for + x-model binding
    // issues in Alpine.js 3 where all checkboxes in a loop can toggle together.
    isCurrencySelected(c) {
      return (this.modalForm.selectedCurrencies || []).includes(c)
    },
    toggleCurrency(c) {
      const arr = [...(this.modalForm.selectedCurrencies || [])]
      const idx = arr.indexOf(c)
      if (idx === -1) arr.push(c)
      else arr.splice(idx, 1)
      this.modalForm.selectedCurrencies = arr
    },

    isPermissionSelected(p) {
      return (this.modalForm.selectedPermissions || []).includes(p)
    },
    togglePermission(p) {
      const arr = [...(this.modalForm.selectedPermissions || [])]
      const idx = arr.indexOf(p)
      if (idx === -1) arr.push(p)
      else arr.splice(idx, 1)
      this.modalForm.selectedPermissions = arr
    },

    // ── Create actions ────────────────────────────────────
    async createAccount() {
      this.loading = true
      try {
        const customerIds = (this.modalForm.customerIds || '')
          .split('\n').map(s => s.trim()).filter(Boolean)
        await this.apiFetch('POST', '/accounts/open', {
          type: this.modalForm.type,
          currencies: this.modalForm.selectedCurrencies || [],
          customer_ids: customerIds,
        }, { idempotency: true })
        this.closeModal()
        this.toast('Account opening requested')
        await this.loadView('accounts')
      } catch (e) {
        this.toast(e.message, 'error')
      } finally {
        this.loading = false
      }
    },

    async createCustomer() {
      this.loading = true
      try {
        await this.apiFetch('POST', '/customers/onboard', {
          name: this.modalForm.name,
          type: this.modalForm.type,
        }, { idempotency: true })
        this.closeModal()
        this.toast('Customer onboarded')
        await this.loadView('customers')
      } catch (e) {
        this.toast(e.message, 'error')
      } finally {
        this.loading = false
      }
    },

    async createUser() {
      this.loading = true
      try {
        await this.apiFetch('POST', '/users/onboard', {
          name: this.modalForm.name,
          email: this.modalForm.email,
        }, { idempotency: true })
        this.closeModal()
        this.toast('User onboarded')
        await this.loadView('users')
      } catch (e) {
        this.toast(e.message, 'error')
      } finally {
        this.loading = false
      }
    },

    async createRole() {
      this.loading = true
      try {
        const scopes = (this.modalForm.scopesList || '')
          .split('\n').map(s => s.trim()).filter(Boolean)
        await this.apiFetch('POST', '/roles/create', {
          name: this.modalForm.name,
          permissions: this.modalForm.selectedPermissions || [],
          scopes,
        }, { idempotency: true })
        this.closeModal()
        this.toast('Role created')
        await this.loadView('roles')
      } catch (e) {
        this.toast(e.message, 'error')
      } finally {
        this.loading = false
      }
    },

    async createScope() {
      this.loading = true
      try {
        const body = { name: this.modalForm.name }
        if (this.modalForm.parent_scope_id?.trim()) {
          body.parent_scope_id = this.modalForm.parent_scope_id.trim()
        }
        await this.apiFetch('POST', '/scopes/create', body, { idempotency: true })
        this.closeModal()
        this.toast('Scope created')
        await this.loadView('scopes')
      } catch (e) {
        this.toast(e.message, 'error')
      } finally {
        this.loading = false
      }
    },

    async generateApiKey() {
      this.loading = true
      try {
        const result = await this.apiFetch('POST', '/api_keys/generate', {
          name: this.modalForm.name,
          user_id: this.modalForm.user_id,
        }, { idempotency: true })
        this.modal = 'api_key_result'
        this.modalForm = { id: result.id, secret: result.secret }
      } catch (e) {
        this.toast(e.message, 'error')
      } finally {
        this.loading = false
      }
    },

    async revokeApiKey(id) {
      if (!confirm('Revoke this API key? This cannot be undone.')) return
      this.loading = true
      try {
        await this.apiFetch('PATCH', '/api_keys/' + id + '/revoke', {
          reason: 'Revoked via dashboard',
        }, { scope: false })
        this.toast('API key revoked')
        await this.loadView('api_keys')
      } catch (e) {
        this.toast(e.message, 'error')
      } finally {
        this.loading = false
      }
    },

    async initiateTransfer() {
      this.loading = true
      try {
        await this.apiFetch('POST', '/transactions/internal_transfers/initiate', {
          amount: parseInt(this.modalForm.amount, 10),
          creditor_account_id: this.modalForm.creditor_account_id,
          currency: this.modalForm.currency,
          debtor_account_id: this.modalForm.debtor_account_id,
          remittance_information: this.modalForm.remittance_information,
        })
        this.closeModal()
        this.toast('Transfer initiated')
        await this.loadView('postings')
      } catch (e) {
        this.toast(e.message, 'error')
      } finally {
        this.loading = false
      }
    },

    // ── Utilities ─────────────────────────────────────────
    toast(msg, type = 'success') {
      const id = Date.now() + Math.random()
      this.toasts.push({ id, msg, type })
      setTimeout(() => {
        this.toasts = this.toasts.filter(t => t.id !== id)
      }, 4500)
    },

    formatDate(str) {
      if (!str) return ''
      try {
        return new Date(str).toLocaleDateString('en-US', {
          month: 'short', day: 'numeric', year: 'numeric',
          hour: '2-digit', minute: '2-digit',
        })
      } catch { return str }
    },
  }
}
