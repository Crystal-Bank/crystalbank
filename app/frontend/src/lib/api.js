import { auth } from './store.svelte.js'

export async function apiFetch(method, path, body = null, opts = {}) {
  const headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ' + auth.token,
  }
  if (opts.scope !== false && auth.scope) headers['X-Scope'] = auth.scope
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
}
