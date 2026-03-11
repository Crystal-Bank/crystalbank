<script>
  import { viewData, pagination, ui } from '../../lib/store.svelte.js'
  import { loadMore, generateApiKey, revokeApiKey, loadView } from '../../lib/actions.js'
  import { formatDate, shortId } from '../../lib/utils.js'

  let showModal = $state(false)
  let keyResult = $state(null)  // { id, secret } — shown after generation
  let form = $state({ name: '', user_id: '' })

  function openModal() {
    form = { name: '', user_id: '' }
    showModal = true
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
      {#if viewData.api_keys.length === 0 && !ui.loading}
        <tr><td colspan="6" class="text-center py-10 text-zinc-400 text-sm">No API keys found</td></tr>
      {/if}
      {#each viewData.api_keys as k (k.id)}
        <tr>
          <td><span class="mono">{shortId(k.id)}</span></td>
          <td class="font-medium">{k.name}</td>
          <td><span class="badge" class:badge-green={k.active} class:badge-red={!k.active}>{k.active ? 'Active' : 'Revoked'}</span></td>
          <td class="text-zinc-500 text-xs">{formatDate(k.created_at)}</td>
          <td><span class="mono text-xs">{shortId(k.scope_id)}</span></td>
          <td>
            {#if k.active}
              <button onclick={() => handleRevoke(k.id)} class="btn btn-danger btn-sm">Revoke</button>
            {/if}
          </td>
        </tr>
      {/each}
    </tbody>
  </table>
  {#if ui.loading && ui.view === 'api_keys'}
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
          <input bind:value={form.user_id} type="text" class="field-input font-mono text-sm" placeholder="UUID of the user" required>
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
