<script>
  import { viewData, pagination, ui } from '../../lib/store.svelte.js'
  import { loadMore, generateApiKey, revokeApiKey, loadView } from '../../lib/actions.js'
  import { apiFetch } from '../../lib/api.js'
  import { formatDate } from '../../lib/utils.js'

  let showModal = $state(false)
  let keyResult = $state(null)  // { id, secret } — shown after generation
  let form = $state({ name: '', user_id: '' })
  let userOptions = $state([])
  let showUserDropdown = $state(false)

  let userSuggestions = $derived(
    userOptions
      .filter(u => {
        const q = form.user_id.toLowerCase()
        return q === '' || u.id.toLowerCase().includes(q) || u.name.toLowerCase().includes(q) || (u.email ?? '').toLowerCase().includes(q)
      })
      .slice(0, 8)
  )

  async function openModal() {
    form = { name: '', user_id: '' }
    showModal = true
    try {
      const res = await apiFetch('GET', '/users/?limit=200')
      userOptions = res.data.map(e => e.attributes)
    } catch { userOptions = [] }
  }

  function selectUser(userId) {
    form.user_id = userId
    showUserDropdown = false
  }

  async function handleSubmit() {
    try {
      const result = await generateApiKey({ name: form.name, user_id: form.user_id })
      showModal = false
      keyResult = result
    } catch {}
  }

  async function handleRevoke(id) {
    if (!confirm('Revoke this API key? This cannot be undone.')) return
    await revokeApiKey(id)
  }

  function handleResultDone() {
    keyResult = null
    loadView('api_keys')
  }

  // ── Detail drawer ─────────────────────────────────────
  let drawerKey = $state(null)

  async function handleRevokeFromDrawer(id) {
    if (!confirm('Revoke this API key? This cannot be undone.')) return
    await revokeApiKey(id)
    drawerKey = null
  }
</script>

<div class="page-header">
  <div>
    <div class="page-title">API Keys</div>
    <div class="page-subtitle">Client credentials for API authentication</div>
  </div>
  <button onclick={openModal} class="btn btn-primary btn-sm">
    <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
    Generate Key
  </button>
</div>

<div class="card overflow-hidden">
  <table class="data-table">
    <thead><tr><th>ID</th><th>Name</th><th>Status</th><th>Created</th><th>Scope</th><th></th></tr></thead>
    <tbody>
      {#if viewData.api_keys.length === 0 && !ui.loadingView}
        <tr><td colspan="6" class="text-center py-10 text-zinc-400 text-sm">No API keys found</td></tr>
      {/if}
      {#each viewData.api_keys as k (k.id)}
        <tr onclick={() => drawerKey = k} class="cursor-pointer">
          <td><span class="mono text-xs">{k.id}</span></td>
          <td class="font-medium">{k.name}</td>
          <td><span class="badge" class:badge-green={k.active} class:badge-red={!k.active}>{k.active ? 'Active' : 'Revoked'}</span></td>
          <td class="text-zinc-500 text-xs">{formatDate(k.created_at)}</td>
          <td><span class="mono text-xs">{k.scope_id}</span></td>
          <td>
            {#if k.active}
              <button onclick={() => handleRevoke(k.id)} class="btn btn-danger btn-sm">Revoke</button>
            {/if}
          </td>
        </tr>
      {/each}
    </tbody>
  </table>
  {#if ui.loadingView === 'api_keys'}
    <div class="flex justify-center py-6">
      <div class="animate-spin w-5 h-5 border-2 border-zinc-300 border-t-zinc-700 rounded-full"></div>
    </div>
  {/if}
  {#if pagination.hasMore.api_keys && !ui.loading}
    <div class="p-4 border-t border-zinc-100 flex justify-center">
      <button onclick={() => loadMore('api_keys')} class="btn btn-ghost btn-sm">Load more</button>
    </div>
  {/if}
</div>

<!-- API Key detail drawer -->
{#if drawerKey}
  <div class="drawer-backdrop" onclick={() => drawerKey = null}></div>
  <div class="drawer-panel">
    <div class="drawer-header">
      <div class="drawer-title">API Key Details</div>
      <button onclick={() => drawerKey = null} class="text-zinc-400 hover:text-zinc-700 transition-colors">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
      </button>
    </div>
    <div class="drawer-body">
      <div class="drawer-field">
        <div class="drawer-field-label">ID</div>
        <div class="font-mono text-xs bg-zinc-50 border border-zinc-200 rounded px-2.5 py-1.5 break-all select-all">{drawerKey.id}</div>
      </div>
      <div class="drawer-field">
        <div class="drawer-field-label">Name</div>
        <div class="drawer-field-value font-medium">{drawerKey.name}</div>
      </div>
      <div class="drawer-field">
        <div class="drawer-field-label">Status</div>
        <div><span class="badge" class:badge-green={drawerKey.active} class:badge-red={!drawerKey.active}>{drawerKey.active ? 'Active' : 'Revoked'}</span></div>
      </div>
      <div class="drawer-field">
        <div class="drawer-field-label">Created</div>
        <div class="drawer-field-value tabular-nums">{formatDate(drawerKey.created_at)}</div>
      </div>
      <div class="drawer-field">
        <div class="drawer-field-label">User ID</div>
        <div class="font-mono text-xs bg-zinc-50 border border-zinc-200 rounded px-2.5 py-1.5 break-all select-all">{drawerKey.user_id}</div>
      </div>
      <div class="drawer-field">
        <div class="drawer-field-label">Scope ID</div>
        <div class="font-mono text-xs bg-zinc-50 border border-zinc-200 rounded px-2.5 py-1.5 break-all select-all">{drawerKey.scope_id}</div>
      </div>
    </div>
    {#if drawerKey.active}
      <div class="drawer-footer">
        <button
          onclick={() => handleRevokeFromDrawer(drawerKey.id)}
          class="btn btn-danger w-full"
          disabled={ui.loading}
        >
          Revoke API Key
        </button>
      </div>
    {/if}
  </div>
{/if}

<!-- Generate API Key modal -->
{#if showModal}
  <div class="modal-backdrop" onclick={(e) => { if (e.target === e.currentTarget) showModal = false }}>
    <div class="modal-box">
      <div class="modal-title">Generate API Key</div>
      <div class="modal-desc">Create a new client credential pair. Requires scope.</div>
      <form onsubmit={(e) => { e.preventDefault(); handleSubmit() }}>
        <div class="mb-4">
          <label class="field-label">Key Name</label>
          <input bind:value={form.name} type="text" class="field-input" placeholder="my-service-key" required>
        </div>
        <div class="mb-5">
          <label class="field-label">User ID</label>
          <div class="relative">
            <input
              bind:value={form.user_id}
              type="text"
              class="field-input font-mono text-sm"
              placeholder="Search users by name or ID..."
              onfocus={() => showUserDropdown = true}
              onblur={() => setTimeout(() => { showUserDropdown = false }, 180)}
              oninput={() => showUserDropdown = true}
              required
            >
            {#if showUserDropdown && userSuggestions.length > 0}
              <div class="absolute top-full left-0 right-0 z-20 bg-white border border-zinc-200 rounded-md shadow-lg mt-0.5 max-h-48 overflow-y-auto">
                {#each userSuggestions as u (u.id)}
                  <button
                    type="button"
                    class="w-full text-left px-3 py-2 hover:bg-zinc-50 border-b border-zinc-100 last:border-0"
                    onmousedown={(e) => { e.preventDefault(); selectUser(u.id) }}
                  >
                    <div class="font-medium text-xs text-zinc-800">{u.name}</div>
                    <div class="font-mono text-xs text-zinc-400 mt-0.5">{u.id}{u.email ? ` · ${u.email}` : ''}</div>
                  </button>
                {/each}
              </div>
            {/if}
          </div>
        </div>
        <div class="flex gap-2 justify-end">
          <button type="button" onclick={() => showModal = false} class="btn btn-ghost">Cancel</button>
          <button type="submit" class="btn btn-primary" disabled={ui.loading}>Generate Key</button>
        </div>
      </form>
    </div>
  </div>
{/if}

<!-- API Key result modal (show secret once) -->
{#if keyResult}
  <div class="modal-backdrop">
    <div class="modal-box">
      <div class="modal-title">API Key Generated</div>
      <div class="modal-desc">Save your secret now &mdash; it will not be shown again.</div>
      <div class="space-y-3 mb-5">
        <div>
          <div class="field-label mb-1">Key ID (Client ID)</div>
          <div class="mono text-sm bg-zinc-50 border border-zinc-200 rounded p-2.5 break-all select-all">{keyResult.id}</div>
        </div>
        <div>
          <div class="field-label mb-1">Secret (Client Secret)</div>
          <div class="mono text-sm bg-amber-50 border border-amber-200 rounded p-2.5 break-all select-all text-amber-900">{keyResult.secret}</div>
        </div>
      </div>
      <div class="bg-amber-50 border border-amber-200 rounded p-3 text-xs text-amber-800 mb-5">
        Store this secret securely. You will not be able to retrieve it again.
      </div>
      <div class="flex justify-end">
        <button onclick={handleResultDone} class="btn btn-primary">Done</button>
      </div>
    </div>
  </div>
{/if}
