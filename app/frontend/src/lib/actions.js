import { auth, ui, viewData, pagination, VIEW_PATHS } from './store.svelte.js'
import { apiFetch } from './api.js'

// ── Toast ────────────────────────────────────────────────

export function addToast(msg, type = 'success') {
  const id = Date.now() + Math.random()
  ui.toasts.push({ id, msg, type })
  setTimeout(() => {
    const idx = ui.toasts.findIndex(t => t.id === id)
    if (idx !== -1) ui.toasts.splice(idx, 1)
  }, 4500)
}

// ── Auth ─────────────────────────────────────────────────

export async function login(clientId, clientSecret) {
  ui.loading = true
  try {
    const res = await fetch('/oauth/token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        grant_type: 'client_credentials',
        client_id: clientId,
        client_secret: clientSecret,
      }),
    })
    if (!res.ok) {
      const err = await res.json().catch(() => ({}))
      throw new Error(err.message || 'Authentication failed')
    }
    const body = await res.json()
    auth.token = body.token
    localStorage.setItem('cb_token', auth.token)
    await loadView('accounts')
  } finally {
    ui.loading = false
  }
}

export function logout() {
  auth.token = ''
  localStorage.removeItem('cb_token')
}

export function setScope(value) {
  auth.scope = value
  auth.scopeInput = value
  if (value) localStorage.setItem('cb_scope', value)
  else localStorage.removeItem('cb_scope')
}

// ── Navigation / data loading ────────────────────────────

export async function switchView(id) {
  if (ui.view === id && viewData[id].length > 0) return
  await loadView(id)
}

export async function loadView(id) {
  ui.view = id
  viewData[id] = []
  pagination.cursors[id] = null
  pagination.hasMore[id] = false
  await loadMore(id)
}

export async function loadMore(id) {
  if (ui.loading) return
  ui.loading = true
  try {
    let url = VIEW_PATHS[id] + '?limit=20'
    if (pagination.cursors[id]) url += '&cursor=' + pagination.cursors[id]
    const res = await apiFetch('GET', url)
    const items = res.data.map(e => e.attributes)
    viewData[id] = [...viewData[id], ...items]
    pagination.hasMore[id] = res.meta.has_more
    pagination.cursors[id] = res.meta.next_cursor || null
  } catch (e) {
    addToast(e.message, 'error')
  } finally {
    ui.loading = false
  }
}

// ── Create / write actions ───────────────────────────────

export async function createAccount({ type, currencies, customerIds }) {
  ui.loading = true
  try {
    const customer_ids = customerIds.split('\n').map(s => s.trim()).filter(Boolean)
    await apiFetch('POST', '/accounts/open', { type, currencies, customer_ids }, { idempotency: true })
    addToast('Account opening requested')
    await loadView('accounts')
  } catch (e) {
    addToast(e.message, 'error')
    throw e
  } finally {
    ui.loading = false
  }
}

export async function createCustomer({ name, type }) {
  ui.loading = true
  try {
    await apiFetch('POST', '/customers/onboard', { name, type }, { idempotency: true })
    addToast('Customer onboarded')
    await loadView('customers')
  } catch (e) {
    addToast(e.message, 'error')
    throw e
  } finally {
    ui.loading = false
  }
}

export async function createUser({ name, email }) {
  ui.loading = true
  try {
    await apiFetch('POST', '/users/onboard', { name, email }, { idempotency: true })
    addToast('User onboarded')
    await loadView('users')
  } catch (e) {
    addToast(e.message, 'error')
    throw e
  } finally {
    ui.loading = false
  }
}

export async function createRole({ name, permissions, scopesList }) {
  ui.loading = true
  try {
    const scopes = scopesList.split('\n').map(s => s.trim()).filter(Boolean)
    await apiFetch('POST', '/roles/create', { name, permissions, scopes }, { idempotency: true })
    addToast('Role created')
    await loadView('roles')
  } catch (e) {
    addToast(e.message, 'error')
    throw e
  } finally {
    ui.loading = false
  }
}

export async function createScope({ name, parent_scope_id }) {
  ui.loading = true
  try {
    const body = { name }
    if (parent_scope_id?.trim()) body.parent_scope_id = parent_scope_id.trim()
    await apiFetch('POST', '/scopes/create', body, { idempotency: true })
    addToast('Scope created')
    await loadView('scopes')
  } catch (e) {
    addToast(e.message, 'error')
    throw e
  } finally {
    ui.loading = false
  }
}

export async function generateApiKey({ name, user_id }) {
  ui.loading = true
  try {
    const result = await apiFetch('POST', '/api_keys/generate', { name, user_id }, { idempotency: true })
    return result
  } catch (e) {
    addToast(e.message, 'error')
    throw e
  } finally {
    ui.loading = false
  }
}

export async function revokeApiKey(id) {
  ui.loading = true
  try {
    await apiFetch('PATCH', '/api_keys/' + id + '/revoke', { reason: 'Revoked via dashboard' }, { scope: false })
    addToast('API key revoked')
    await loadView('api_keys')
  } catch (e) {
    addToast(e.message, 'error')
  } finally {
    ui.loading = false
  }
}

export async function createLedgerTransaction({ currency, entries, posting_date, value_date, remittance_information, metadata }) {
  ui.loading = true
  try {
    const meta = Object.fromEntries(Object.entries(metadata ?? {}).filter(([, v]) => v !== undefined && v !== ''))
    await apiFetch('POST', '/ledger/transactions', {
      currency,
      entries,
      posting_date,
      value_date,
      remittance_information,
      ...(Object.keys(meta).length > 0 ? { metadata: meta } : {}),
    }, { idempotency: true })
    addToast('Transaction created')
    await loadView('postings')
  } catch (e) {
    addToast(e.message, 'error')
    throw e
  } finally {
    ui.loading = false
  }
}
