<script>
  import { viewData, pagination, ui, ALL_PERMISSIONS } from '../../lib/store.svelte.js'
  import { loadMore, createRole } from '../../lib/actions.js'

  let showModal = $state(false)
  let form = $state({ name: '', selectedPermissions: [], scopesList: '' })

  function openModal() {
    form = { name: '', selectedPermissions: [], scopesList: '' }
    showModal = true
  }

  function togglePermission(p) {
    const idx = form.selectedPermissions.indexOf(p)
    if (idx === -1) form.selectedPermissions = [...form.selectedPermissions, p]
    else form.selectedPermissions = form.selectedPermissions.filter(x => x !== p)
  }

  async function handleSubmit() {
    try {
      await createRole({ name: form.name, permissions: form.selectedPermissions, scopesList: form.scopesList })
      showModal = false
    } catch {}
  }
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
    <div class="card p-4">
      <div class="flex items-center gap-2 mb-2">
        <span class="font-semibold text-sm">{r.name}</span>
        <span class="mono text-xs">{r.id}</span>
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
            {#each ALL_PERMISSIONS as p (p)}
              <label class="permission-item">
                <input type="checkbox" checked={form.selectedPermissions.includes(p)} onchange={() => togglePermission(p)}>
                <span class="font-mono">{p}</span>
              </label>
            {/each}
          </div>
        </div>
        <div class="mb-5">
          <label class="field-label">Scope UUIDs</label>
          <textarea bind:value={form.scopesList} class="field-input" rows="2" placeholder="One UUID per line..."></textarea>
          <div class="field-hint">One scope UUID per line</div>
        </div>
        <div class="flex gap-2 justify-end">
          <button type="button" onclick={() => showModal = false} class="btn btn-ghost">Cancel</button>
          <button type="submit" class="btn btn-primary" disabled={ui.loading}>Create Role</button>
        </div>
      </form>
    </div>
  </div>
{/if}
