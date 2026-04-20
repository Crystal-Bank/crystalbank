import { auth, ui } from './store.svelte.js'

// Injected at runtime by the Crystal server into window.__API_URL__.
// Falls back to empty string so relative paths work in a Vite dev-server session.
export const API_BASE = window.__API_URL__ ?? ''

function clearSession() {
  auth.token = ''
  localStorage.removeItem('cb_token')
}

export async function apiFetch(method, path, body = null, opts = {}) {
  const headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ' + auth.token,
  }
  if (opts.scope !== false && auth.scope) headers['X-Scope'] = auth.scope
  if (opts.idempotency) headers['idempotency_key'] = crypto.randomUUID()

  const res = await fetch(API_BASE + path, {
    method,
    headers,
    body: body ? JSON.stringify(body) : null,
  })

  if (res.status === 401) {
    clearSession()
    throw new Error('Session expired')
  }

  if (res.status === 403) {
    let msg = 'You do not have permission to perform this action.'
    try { const e = await res.json(); msg = e.message || msg } catch {}
    ui.permissionError = msg
    throw new Error(msg)
  }

  if (!res.ok) {
    let msg = 'Request failed (' + res.status + ')'
    try { const e = await res.json(); msg = e.message || msg } catch {}
    throw new Error(msg)
  }

  if (res.status === 204 || res.headers.get('Content-Length') === '0') return {}
  return res.json()
}
