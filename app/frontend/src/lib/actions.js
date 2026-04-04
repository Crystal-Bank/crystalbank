import { auth, ui, viewData, pagination, VIEW_PATHS, approvalsMeta } from './store.svelte.js'
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
    auth.scope = ''
    auth.scopeInput = ''
    localStorage.removeItem('cb_scope')
    window.location.hash = 'dashboard'
    ui.view = 'dashboard'
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
  if (VIEW_PATHS[ui.view]) loadView(ui.view)
}

// ── Navigation / data loading ────────────────────────────

export async function switchView(id) {
  if (!VIEW_PATHS[id]) { ui.view = id; window.location.hash = id; return }
  if (ui.view === id && viewData[id].length > 0) return
  await loadView(id)
}

export async function loadView(id) {
  window.location.hash = id
  ui.view = id
  ui.loadingView = null  // clear any stale per-view lock before starting
  viewData[id] = []
  pagination.cursors[id] = null
  pagination.hasMore[id] = false
  await loadMore(id)
}

// Silent background refresh — does not touch ui.loading or clear existing data.
// Replaces the first page only; skips entirely if a foreground load is in progress.
export async function refreshView(id) {
  if (!VIEW_PATHS[id] || ui.loadingView) return
  try {
    const base = VIEW_PATHS[id]
    const sep = base.includes('?') ? '&' : '?'
    const res = await apiFetch('GET', base + sep + 'limit=20')
    const items = res.data.map(e => e.attributes)
    if (
      (items.length === 0 && viewData[id].length > 0) ||
      JSON.stringify(items) !== JSON.stringify(viewData[id].slice(0, items.length)) ||
      res.meta.has_more !== pagination.hasMore[id]
    ) {
      viewData[id] = items
      pagination.hasMore[id] = res.meta.has_more
      pagination.cursors[id] = res.meta.next_cursor || null
    }
  } catch {}
}

export async function loadMore(id) {
  if (ui.loadingView === id) return  // guard: only prevent concurrent loads for the SAME view
  ui.loading = true
  ui.loadingView = id
  try {
    const base = VIEW_PATHS[id]
    const sep = base.includes('?') ? '&' : '?'
    let url = base + sep + 'limit=20'
    if (pagination.cursors[id]) url += '&cursor=' + pagination.cursors[id]
    const res = await apiFetch('GET', url)
    const items = res.data.map(e => e.attributes)
    viewData[id] = [...viewData[id], ...items]
    pagination.hasMore[id] = res.meta.has_more
    pagination.cursors[id] = res.meta.next_cursor || null
  } catch (e) {
    addToast(e.message, 'error')
  } finally {
    if (ui.loadingView === id) {
      ui.loading = false
      ui.loadingView = null
    }
  }
}

// ── Create / write actions ───────────────────────────────

export async function createAccount({ name, type, currencies, customerIds }) {
  ui.loading = true
  try {
    const customer_ids = Array.isArray(customerIds)
      ? customerIds
      : customerIds.split('\n').map(s => s.trim()).filter(Boolean)
    await apiFetch('POST', '/accounts/open', { name, type, currencies, customer_ids }, { idempotency: true })
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
    addToast('Customer onboarding requested')
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
    addToast('User creation submitted for approval')
    await loadView('users')
  } catch (e) {
    addToast(e.message, 'error')
    throw e
  } finally {
    ui.loading = false
  }
}

export async function assignRoles(userId, roleIds) {
  ui.loading = true
  try {
    await apiFetch('POST', '/users/' + userId + '/assign_roles', { role_ids: roleIds }, { idempotency: true })
    addToast('Roles assigned')
    await loadView('users')
  } catch (e) {
    addToast(e.message, 'error')
    throw e
  } finally {
    ui.loading = false
  }
}

export async function createRole({ name, permissions, scopesList, selectedScopes }) {
  ui.loading = true
  try {
    const scopes = selectedScopes ?? (scopesList ? scopesList.split('\n').map(s => s.trim()).filter(Boolean) : [])
    await apiFetch('POST', '/roles/create', { name, permissions, scopes }, { idempotency: true })
    addToast('Role creation requested')
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
    addToast('Scope creation requested')
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
      ...(remittance_information ? { remittance_information } : {}),
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

export async function createSepaCreditTransfer(payload) {
  ui.loading = true
  try {
    await apiFetch('POST', '/payments/sepa/credit-transfers/', payload, { idempotency: true })
    addToast('SEPA Credit Transfer submitted — awaiting approval')
    await loadView('sepa_credit_transfers')
  } catch (e) {
    addToast(e.message, 'error')
    throw e
  } finally {
    ui.loading = false
  }
}

export async function requestBlock(accountId, blockType, reason) {
  ui.loading = true
  try {
    const res = await apiFetch(
      'POST',
      `/accounts/${accountId}/blocks`,
      { block_type: blockType, ...(reason ? { reason } : {}) },
      { idempotency: true },
    )
    addToast('Block requested — awaiting approval')
    return res
  } catch (e) {
    addToast(e.message, 'error')
    throw e
  } finally {
    ui.loading = false
  }
}

export async function requestUnblock(accountId, blockType, reason) {
  ui.loading = true
  try {
    const url = `/accounts/${accountId}/blocks/${blockType}` +
      (reason ? `?reason=${encodeURIComponent(reason)}` : '')
    const res = await apiFetch('DELETE', url)
    addToast('Unblock requested — awaiting approval')
    return res
  } catch (e) {
    addToast(e.message, 'error')
    throw e
  } finally {
    ui.loading = false
  }
}

export async function collectApproval(id, comment) {
  ui.loading = true
  try {
    const res = await apiFetch('POST', '/approvals/' + id + '/collect', { comment }, { idempotency: true })
    addToast('Approval collected')
    if (res.status === 'completed') {
      // All required approvals collected — remove from pending list immediately
      viewData.approvals = viewData.approvals.filter(a => a.id !== id)
      approvalsMeta.completedDirty = true
    } else {
      // More approvals still required — refresh to show updated progress
      refreshView('approvals')
    }
  } catch (e) {
    addToast(e.message, 'error')
    throw e
  } finally {
    ui.loading = false
  }
}

export async function rejectApproval(id, comment) {
  ui.loading = true
  try {
    await apiFetch('POST', '/approvals/' + id + '/reject', { comment }, { idempotency: true })
    addToast('Approval rejected')
    // Remove from pending list immediately and mark rejected list as dirty
    viewData.approvals = viewData.approvals.filter(a => a.id !== id)
    approvalsMeta.rejectedDirty = true
  } catch (e) {
    addToast(e.message, 'error')
    throw e
  } finally {
    ui.loading = false
  }
}
