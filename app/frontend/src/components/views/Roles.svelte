<script>
  import { viewData, pagination, ui } from '../../lib/store.svelte.js'
  import { loadMore, createRole } from '../../lib/actions.js'
  import { apiFetch } from '../../lib/api.js'
  import { statusBadgeClass, formatStatus } from '../../lib/utils.js'

  let showModal = $state(false)
  let form = $state({ name: '', selectedPermissions: [], selectedScopes: [] })
  let scopeOptions = $state([])
  let permissionOptions = $state([])
  let scopeSearch = $state('')
  let showScopeDropdown = $state(false)

  let scopeSuggestions = $derived(
    scopeOptions
      .filter(s => {
        if (form.selectedScopes.includes(s.id)) return false
        const q = scopeSearch.toLowerCase()
        return q === '' || s.id.toLowerCase().includes(q) || s.name.toLowerCase().includes(q)
      })
      .slice(0, 8)
  )

  async function openModal() {
    form = { name: '', selectedPermissions: [], selectedScopes: [] }
    scopeSearch = ''
    showModal = true
    const results = await Promise.allSettled([
      apiFetch('GET', '/scopes/?limit=200'),
      apiFetch('GET', '/platform/types/permissions'),
    ])
    scopeOptions = results[0].status === 'fulfilled'
      ? results[0].value.data.map(e => e.attributes).filter(s => s.status === 'active')
      : []
    permissionOptions = results[1].status === 'fulfilled' ? results[1].value.values : []
  }

  function togglePermission(p) {
    const idx = form.selectedPermissions.indexOf(p)
    if (idx === -1) form.selectedPermissions = [...form.selectedPermissions, p]
    else form.selectedPermissions = form.selectedPermissions.filter(x => x !== p)
  }

  function addScope(scopeId) {
    if (!form.selectedScopes.includes(scopeId)) {
      form.selectedScopes = [...form.selectedScopes, scopeId]
    }
    scopeSearch = ''
    showScopeDropdown = false
  }

  function removeScope(scopeId) {
    form.selectedScopes = form.selectedScopes.filter(id => id !== scopeId)
  }

  function getScopeName(scopeId) {
    return scopeOptions.find(s => s.id === scopeId)?.name ?? scopeId
  }

  async function handleSubmit() {
    try {
      await createRole({ name: form.name, permissions: form.selectedPermissions, selectedScopes: form.selectedScopes })
      showModal = false
    } catch {}
  }

  // ── Detail drawer ─────────────────────────────────────
  let drawerRole = $state(null)
</script>

<div class="page-header">
  <div>
    <div class="page-title">Roles</div>
    <div class="page-subtitle">Permission roles for access control</div>
  </div>
  <button onclick={openModal} class="btn btn-primary btn-sm">
    <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
    Create Role
  </button>
</div>

<div class="space-y-3">
  {#if viewData.roles.length === 0 && !ui.loadingView}
    <div class="card p-10 text-center text-zinc-400 text-sm">No roles found</div>
  {/if}
  {#each viewData.roles as r (r.id)}
    <div class="card p-4 cursor-pointer" onclick={() => drawerRole = r}>
      <div class="flex items-center gap-2 mb-2">
        <span class="font-semibold text-sm">{r.name}</span>
        <span class="mono text-xs">{r.id}</span>
        <span class="badge {statusBadgeClass(r.status)}">{formatStatus(r.status)}</span>
      </div>
      <div class="flex flex-wrap gap-1.5">
        {#each r.permissions ?? [] as p (p)}
          <span class="badge badge-blue">{p}</span>
        {/each}
      </div>
      {#if r.scopes?.length > 0}
        <div class="mt-2 flex flex-wrap items-center gap-1">
          <span class="text-xs text-zinc-400">Scopes:</span>
          {#each r.scopes as s (s)}
            <span class="mono text-xs">{s}</span>
          {/each}
        </div>
      {/if}
    </div>
  {/each}
</div>

{#if ui.loadingView === 'roles'}
  <div class="flex justify-center py-6">
    <div class="animate-spin w-5 h-5 border-2 border-zinc-300 border-t-zinc-700 rounded-full"></div>
  </div>
{/if}
{#if pagination.hasMore.roles && !ui.loading}
  <div class="mt-4 flex justify-center">
    <button onclick={() => loadMore('roles')} class="btn btn-ghost btn-sm">Load more</button>
  </div>
{/if}

<!-- Role detail drawer -->
{#if drawerRole}
  <div class="drawer-backdrop" onclick={() => drawerRole = null}></div>
  <div class="drawer-panel">
    <div class="drawer-header">
      <div class="drawer-title">Role Details</div>
      <button onclick={() => drawerRole = null} class="text-zinc-400 hover:text-zinc-700 transition-colors">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
      </button>
    </div>
    <div class="drawer-body">
      <div class="drawer-field">
        <div class="drawer-field-label">ID</div>
        <div class="font-mono text-xs bg-zinc-50 border border-zinc-200 rounded px-2.5 py-1.5 break-all select-all">{drawerRole.id}</div>
      </div>
      <div class="drawer-field">
        <div class="drawer-field-label">Name</div>
        <div class="drawer-field-value font-medium">{drawerRole.name}</div>
      </div>
      <div class="drawer-field">
        <div class="drawer-field-label">Status</div>
        <div><span class="badge {statusBadgeClass(drawerRole.status)}">{formatStatus(drawerRole.status)}</span></div>
      </div>
      <div class="drawer-field">
        <div class="drawer-field-label">Permissions</div>
        <div class="flex flex-wrap gap-1">
          {#each drawerRole.permissions ?? [] as p (p)}
            <span class="badge badge-blue">{p}</span>
          {/each}
          {#if (drawerRole.permissions ?? []).length === 0}
            <span class="text-zinc-400 text-xs">None</span>
          {/if}
        </div>
      </div>
      {#if drawerRole.scopes?.length > 0}
        <div class="drawer-field">
          <div class="drawer-field-label">Scopes</div>
          <div class="space-y-1">
            {#each drawerRole.scopes as s (s)}
              <div class="font-mono text-xs bg-zinc-50 border border-zinc-200 rounded px-2.5 py-1.5 break-all select-all">{s}</div>
            {/each}
          </div>
        </div>
      {/if}
    </div>
  </div>
{/if}

{#if showModal}
  <div class="modal-backdrop" onclick={(e) => { if (e.target === e.currentTarget) showModal = false }}>
    <div class="modal-box">
      <div class="modal-title">Create Role</div>
      <div class="modal-desc">Define a new permission role. Requires scope.</div>
      <form onsubmit={(e) => { e.preventDefault(); handleSubmit() }}>
        <div class="mb-4">
          <label class="field-label">Role Name</label>
          <input bind:value={form.name} type="text" class="field-input" placeholder="admin" required>
        </div>
        <div class="mb-4">
          <label class="field-label">Permissions</label>
          <div class="permission-list">
            {#each permissionOptions as p (p)}
              <label class="permission-item">
                <input type="checkbox" checked={form.selectedPermissions.includes(p)} onchange={() => togglePermission(p)}>
                <span class="font-mono">{p}</span>
              </label>
            {/each}
          </div>
        </div>
        <div class="mb-5">
          <label class="field-label">Scope UUIDs</label>
          {#if form.selectedScopes.length > 0}
            <div class="flex flex-wrap gap-1.5 mb-2">
              {#each form.selectedScopes as scopeId (scopeId)}
                <span class="inline-flex items-center gap-1 bg-zinc-100 border border-zinc-200 rounded px-2 py-0.5 text-xs">
                  <span class="font-mono text-zinc-700">{getScopeName(scopeId)}</span>
                  <button type="button" onclick={() => removeScope(scopeId)} class="text-zinc-400 hover:text-red-500 leading-none">&times;</button>
                </span>
              {/each}
            </div>
          {/if}
          <div class="relative">
            <input
              type="text"
              bind:value={scopeSearch}
              onfocus={() => showScopeDropdown = true}
              onblur={() => setTimeout(() => { showScopeDropdown = false }, 180)}
              oninput={() => showScopeDropdown = true}
              class="field-input"
              placeholder="Search scopes by name or UUID..."
            >
            {#if showScopeDropdown && scopeSuggestions.length > 0}
              <div class="absolute top-full left-0 right-0 z-20 bg-white border border-zinc-200 rounded-md shadow-lg mt-0.5 max-h-48 overflow-y-auto">
                {#each scopeSuggestions as s (s.id)}
                  <button
                    type="button"
                    class="w-full text-left px-3 py-2 hover:bg-zinc-50 border-b border-zinc-100 last:border-0"
                    onmousedown={(e) => { e.preventDefault(); addScope(s.id) }}
                  >
                    <div class="font-medium text-xs text-zinc-800">{s.name}</div>
                    <div class="font-mono text-xs text-zinc-400 mt-0.5">{s.id}</div>
                  </button>
                {/each}
              </div>
            {/if}
          </div>
          <div class="field-hint">Search and select scope(s) to restrict this role to</div>
        </div>
        <div class="flex gap-2 justify-end">
          <button type="button" onclick={() => showModal = false} class="btn btn-ghost">Cancel</button>
          <button type="submit" class="btn btn-primary" disabled={ui.loading}>Create Role</button>
        </div>
      </form>
    </div>
  </div>
{/if}
