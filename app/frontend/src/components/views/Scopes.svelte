<script>
  import { viewData, pagination, ui } from '../../lib/store.svelte.js'
  import { loadMore, createScope } from '../../lib/actions.js'
  import { apiFetch } from '../../lib/api.js'

  let showModal = $state(false)
  let form = $state({ name: '', parent_scope_id: '' })
  let scopeOptions = $state([])
  let showParentDropdown = $state(false)

  let parentSuggestions = $derived(
    scopeOptions
      .filter(s => {
        const q = form.parent_scope_id.toLowerCase()
        return q === '' || s.id.toLowerCase().includes(q) || s.name.toLowerCase().includes(q)
      })
      .slice(0, 8)
  )

  async function openModal() {
    form = { name: '', parent_scope_id: '' }
    showModal = true
    try {
      const res = await apiFetch('GET', '/scopes/?limit=200')
      scopeOptions = res.data.map(e => e.attributes)
    } catch { scopeOptions = [] }
  }

  function selectParentScope(scopeId) {
    form.parent_scope_id = scopeId
    showParentDropdown = false
  }

  async function handleSubmit() {
    try {
      await createScope({ name: form.name, parent_scope_id: form.parent_scope_id })
      showModal = false
    } catch {}
  }

  // ── Detail drawer ─────────────────────────────────────
  let drawerScope = $state(null)
</script>

<div class="page-header">
  <div>
    <div class="page-title">Scopes</div>
    <div class="page-subtitle">Hierarchical data ownership scopes</div>
  </div>
  <button onclick={openModal} class="btn btn-primary btn-sm">
    <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
    Create Scope
  </button>
</div>

<div class="card overflow-hidden">
  <table class="data-table">
    <thead><tr><th>ID</th><th>Name</th><th>Parent Scope</th><th>Status</th></tr></thead>
    <tbody>
      {#if viewData.scopes.length === 0 && !ui.loadingView}
        <tr><td colspan="4" class="text-center py-10 text-zinc-400 text-sm">No scopes found</td></tr>
      {/if}
      {#each viewData.scopes as s (s.id)}
        <tr onclick={() => drawerScope = s} class="cursor-pointer">
          <td><span class="mono text-xs">{s.id}</span></td>
          <td class="font-medium">{s.name}</td>
          <td>
            {#if s.parent_scope_id}
              <span class="mono text-xs">{s.parent_scope_id}</span>
            {:else}
              <span class="text-zinc-400 text-xs">Root</span>
            {/if}
          </td>
          <td>
            {#if s.accepted}
              <span class="badge badge-green">Active</span>
            {:else}
              <span class="badge badge-amber">Pending</span>
            {/if}
          </td>
        </tr>
      {/each}
    </tbody>
  </table>
  {#if ui.loadingView === 'scopes'}
    <div class="flex justify-center py-6">
      <div class="animate-spin w-5 h-5 border-2 border-zinc-300 border-t-zinc-700 rounded-full"></div>
    </div>
  {/if}
  {#if pagination.hasMore.scopes && !ui.loading}
    <div class="p-4 border-t border-zinc-100 flex justify-center">
      <button onclick={() => loadMore('scopes')} class="btn btn-ghost btn-sm">Load more</button>
    </div>
  {/if}
</div>

<!-- Scope detail drawer -->
{#if drawerScope}
  <div class="drawer-backdrop" onclick={() => drawerScope = null}></div>
  <div class="drawer-panel">
    <div class="drawer-header">
      <div class="drawer-title">Scope Details</div>
      <button onclick={() => drawerScope = null} class="text-zinc-400 hover:text-zinc-700 transition-colors">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
      </button>
    </div>
    <div class="drawer-body">
      <div class="drawer-field">
        <div class="drawer-field-label">ID</div>
        <div class="font-mono text-xs bg-zinc-50 border border-zinc-200 rounded px-2.5 py-1.5 break-all select-all">{drawerScope.id}</div>
      </div>
      <div class="drawer-field">
        <div class="drawer-field-label">Name</div>
        <div class="drawer-field-value font-medium">{drawerScope.name}</div>
      </div>
      <div class="drawer-field">
        <div class="drawer-field-label">Parent Scope ID</div>
        {#if drawerScope.parent_scope_id}
          <div class="font-mono text-xs bg-zinc-50 border border-zinc-200 rounded px-2.5 py-1.5 break-all select-all">{drawerScope.parent_scope_id}</div>
        {:else}
          <div class="drawer-field-value text-zinc-400">Root scope</div>
        {/if}
      </div>
      <div class="drawer-field">
        <div class="drawer-field-label">Status</div>
        <div>
          {#if drawerScope.accepted}
            <span class="badge badge-green">Active</span>
          {:else}
            <span class="badge badge-amber">Pending approval</span>
          {/if}
        </div>
      </div>
    </div>
  </div>
{/if}

{#if showModal}
  <div class="modal-backdrop" onclick={(e) => { if (e.target === e.currentTarget) showModal = false }}>
    <div class="modal-box">
      <div class="modal-title">Create Scope</div>
      <div class="modal-desc">Define a new data ownership scope. Requires scope.</div>
      <form onsubmit={(e) => { e.preventDefault(); handleSubmit() }}>
        <div class="mb-4">
          <label class="field-label">Scope Name</label>
          <input bind:value={form.name} type="text" class="field-input" placeholder="europe" required>
        </div>
        <div class="mb-5">
          <label class="field-label">
            Parent Scope ID
            <span class="text-zinc-400 font-normal">(optional)</span>
          </label>
          <div class="relative">
            <input
              bind:value={form.parent_scope_id}
              type="text"
              class="field-input font-mono text-sm"
              placeholder="Search scopes by name or UUID..."
              onfocus={() => showParentDropdown = true}
              onblur={() => setTimeout(() => { showParentDropdown = false }, 180)}
              oninput={() => showParentDropdown = true}
            >
            {#if showParentDropdown && parentSuggestions.length > 0}
              <div class="absolute top-full left-0 right-0 z-20 bg-white border border-zinc-200 rounded-md shadow-lg mt-0.5 max-h-48 overflow-y-auto">
                {#each parentSuggestions as s (s.id)}
                  <button
                    type="button"
                    class="w-full text-left px-3 py-2 hover:bg-zinc-50 border-b border-zinc-100 last:border-0"
                    onmousedown={(e) => { e.preventDefault(); selectParentScope(s.id) }}
                  >
                    <div class="font-medium text-xs text-zinc-800">{s.name}</div>
                    <div class="font-mono text-xs text-zinc-400 mt-0.5">{s.id}</div>
                  </button>
                {/each}
              </div>
            {/if}
          </div>
          <div class="field-hint">Leave empty to create a root scope</div>
        </div>
        <div class="flex gap-2 justify-end">
          <button type="button" onclick={() => showModal = false} class="btn btn-ghost">Cancel</button>
          <button type="submit" class="btn btn-primary" disabled={ui.loading}>Create Scope</button>
        </div>
      </form>
    </div>
  </div>
{/if}
