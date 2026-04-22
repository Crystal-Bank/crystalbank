<script>
  import { viewData, pagination, ui } from '../../lib/store.svelte.js'
  import { loadMore, createUser, assignRoles, removeRoles } from '../../lib/actions.js'
  import { apiFetch } from '../../lib/api.js'
  import { statusBadgeClass, formatStatus } from '../../lib/utils.js'

  // ── Onboard modal ────────────────────────────────────
  let showOnboardModal = $state(false)
  let form = $state({ name: '', email: '' })

  function openOnboardModal() {
    form = { name: '', email: '' }
    showOnboardModal = true
  }

  async function handleOnboard() {
    try {
      await createUser({ name: form.name, email: form.email })
      showOnboardModal = false
    } catch {}
  }

  // ── User drawer ──────────────────────────────────────
  let drawerUser = $state(null)

  // ── Remove roles (inside drawer) ─────────────────────
  let rolesToRemove = $state([])

  function toggleRemoveRole(roleId) {
    if (rolesToRemove.includes(roleId)) {
      rolesToRemove = rolesToRemove.filter(id => id !== roleId)
    } else {
      rolesToRemove = [...rolesToRemove, roleId]
    }
  }

  async function handleRemove() {
    try {
      await removeRoles(drawerUser.id, rolesToRemove)
      rolesToRemove = []
    } catch {}
  }

  function openDrawer(user) {
    drawerUser = user
    roleOptions = []
    selectedRoles = []
    rolesToRemove = []
    roleSearch = ''
    showRoleDropdown = false
    rolesLoaded = false
    if (user.role_ids && user.role_ids.length > 0) loadRoles()
  }

  function closeDrawer() {
    drawerUser = null
  }

  // ── Assign roles (inside drawer) ─────────────────────
  let roleOptions = $state([])
  let selectedRoles = $state([])
  let roleSearch = $state('')
  let showRoleDropdown = $state(false)
  let rolesLoaded = $state(false)

  async function loadRoles() {
    if (rolesLoaded) return
    try {
      const res = await apiFetch('GET', '/roles/?limit=200')
      roleOptions = res.data.map(e => e.attributes)
      rolesLoaded = true
    } catch { roleOptions = [] }
  }

  let roleSuggestions = $derived(
    roleOptions
      .filter(r => {
        if (selectedRoles.includes(r.id)) return false
        const q = roleSearch.toLowerCase()
        return q === '' || r.id.toLowerCase().includes(q) || r.name.toLowerCase().includes(q)
      })
      .slice(0, 8)
  )

  function addRole(roleId) {
    if (!selectedRoles.includes(roleId)) selectedRoles = [...selectedRoles, roleId]
    roleSearch = ''
    showRoleDropdown = false
  }

  function removeRole(roleId) {
    selectedRoles = selectedRoles.filter(id => id !== roleId)
  }

  function getRoleName(roleId) {
    return roleOptions.find(r => r.id === roleId)?.name ?? roleId
  }

  async function handleAssign() {
    try {
      await assignRoles(drawerUser.id, selectedRoles)
      selectedRoles = []
      roleSearch = ''
    } catch {}
  }

  // Load roles lazily when the assign section is first interacted with
  function handleRoleFocus() {
    loadRoles()
    showRoleDropdown = true
  }
</script>

<div class="page-header">
  <div>
    <div class="page-title">Users</div>
    <div class="page-subtitle">System users with assigned roles</div>
  </div>
  <button onclick={openOnboardModal} class="btn btn-primary btn-sm">
    <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
    Onboard User
  </button>
</div>

<div class="card overflow-hidden">
  <table class="data-table">
    <thead><tr><th>ID</th><th>Name</th><th>Email</th><th>Status</th><th>Scope</th></tr></thead>
    <tbody>
      {#if viewData.users.length === 0 && !ui.loadingView}
        <tr><td colspan="5" class="text-center py-10 text-zinc-400 text-sm">No users found</td></tr>
      {/if}
      {#each viewData.users as u (u.id)}
        <tr onclick={() => openDrawer(u)} class="cursor-pointer">
          <td><span class="mono text-xs">{u.id}</span></td>
          <td class="font-medium">{u.name}</td>
          <td class="text-zinc-500">{u.email}</td>
          <td><span class="badge {statusBadgeClass(u.status)}">{formatStatus(u.status)}</span></td>
          <td><span class="mono text-xs">{u.scope_id}</span></td>
        </tr>
      {/each}
    </tbody>
  </table>
  {#if ui.loadingView === 'users'}
    <div class="flex justify-center py-6">
      <div class="animate-spin w-5 h-5 border-2 border-zinc-300 border-t-zinc-700 rounded-full"></div>
    </div>
  {/if}
  {#if pagination.hasMore.users && !ui.loading}
    <div class="p-4 border-t border-zinc-100 flex justify-center">
      <button onclick={() => loadMore('users')} class="btn btn-ghost btn-sm">Load more</button>
    </div>
  {/if}
</div>

<!-- User detail drawer -->
{#if drawerUser}
  <div class="drawer-backdrop" onclick={closeDrawer}></div>
  <div class="drawer-panel">
    <div class="drawer-header">
      <div class="drawer-title">User Details</div>
      <button onclick={closeDrawer} class="text-zinc-400 hover:text-zinc-700 transition-colors">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
      </button>
    </div>

    <div class="drawer-body">
      <div class="drawer-field">
        <div class="drawer-field-label">ID</div>
        <div class="drawer-field-value font-mono text-xs bg-zinc-50 border border-zinc-200 rounded px-2.5 py-1.5 break-all select-all">{drawerUser.id}</div>
      </div>
      <div class="drawer-field">
        <div class="drawer-field-label">Name</div>
        <div class="drawer-field-value font-medium">{drawerUser.name}</div>
      </div>
      <div class="drawer-field">
        <div class="drawer-field-label">Email</div>
        <div class="drawer-field-value">{drawerUser.email}</div>
      </div>
      <div class="drawer-field">
        <div class="drawer-field-label">Status</div>
        <div><span class="badge {statusBadgeClass(drawerUser.status)}">{formatStatus(drawerUser.status)}</span></div>
      </div>
      <div class="drawer-field">
        <div class="drawer-field-label">Scope ID</div>
        <div class="drawer-field-value font-mono text-xs bg-zinc-50 border border-zinc-200 rounded px-2.5 py-1.5 break-all select-all">{drawerUser.scope_id}</div>
      </div>

      <div class="border-t border-zinc-100 pt-5 mt-1">
        <div class="text-sm font-semibold text-zinc-700 mb-3">Assign Roles</div>

        {#if selectedRoles.length > 0}
          <div class="flex flex-wrap gap-1.5 mb-2">
            {#each selectedRoles as roleId (roleId)}
              <span class="inline-flex items-center gap-1 bg-zinc-100 border border-zinc-200 rounded px-2 py-0.5 text-xs">
                <span class="font-mono text-zinc-700">{getRoleName(roleId)}</span>
                <button type="button" onclick={() => removeRole(roleId)} class="text-zinc-400 hover:text-red-500 leading-none">&times;</button>
              </span>
            {/each}
          </div>
        {/if}

        <div class="relative">
          <input
            type="text"
            bind:value={roleSearch}
            onfocus={handleRoleFocus}
            onblur={() => setTimeout(() => { showRoleDropdown = false }, 180)}
            oninput={() => showRoleDropdown = true}
            class="field-input"
            placeholder="Search roles by name or ID..."
          >
          {#if showRoleDropdown && roleSuggestions.length > 0}
            <div class="absolute top-full left-0 right-0 z-20 bg-white border border-zinc-200 rounded-md shadow-lg mt-0.5 max-h-48 overflow-y-auto">
              {#each roleSuggestions as r (r.id)}
                <button
                  type="button"
                  class="w-full text-left px-3 py-2 hover:bg-zinc-50 border-b border-zinc-100 last:border-0"
                  onmousedown={(e) => { e.preventDefault(); addRole(r.id) }}
                >
                  <div class="font-medium text-xs text-zinc-800">{r.name}</div>
                  <div class="font-mono text-xs text-zinc-400 mt-0.5">{r.id}</div>
                </button>
              {/each}
            </div>
          {/if}
        </div>
        <div class="field-hint">Search and select role(s) to assign to this user</div>
      </div>

      {#if drawerUser.role_ids && drawerUser.role_ids.length > 0}
        <div class="border-t border-zinc-100 pt-5 mt-1">
          <div class="text-sm font-semibold text-zinc-700 mb-3">Remove Roles</div>
          <div class="flex flex-wrap gap-1.5">
            {#each drawerUser.role_ids as roleId (roleId)}
              <button
                type="button"
                onclick={() => toggleRemoveRole(roleId)}
                class="inline-flex items-center gap-1 rounded px-2 py-0.5 text-xs border transition-colors {rolesToRemove.includes(roleId) ? 'bg-red-50 border-red-300 text-red-700' : 'bg-zinc-100 border-zinc-200 text-zinc-700 hover:border-red-300 hover:text-red-600'}"
              >
                <span class="font-mono">{getRoleName(roleId)}</span>
                {#if rolesToRemove.includes(roleId)}
                  <span class="leading-none">&#x2715;</span>
                {/if}
              </button>
            {/each}
          </div>
          <div class="field-hint mt-2">Click a role to mark it for removal</div>
        </div>
      {/if}
    </div>

    <div class="drawer-footer flex flex-col gap-2">
      <button
        onclick={handleAssign}
        class="btn btn-primary w-full"
        disabled={ui.loading || selectedRoles.length === 0}
      >
        Assign Roles
      </button>
      {#if drawerUser.role_ids && drawerUser.role_ids.length > 0}
        <button
          onclick={handleRemove}
          class="btn btn-ghost w-full text-red-600 hover:bg-red-50 border border-red-200"
          disabled={ui.loading || rolesToRemove.length === 0}
        >
          Remove Selected Roles
        </button>
      {/if}
    </div>
  </div>
{/if}

<!-- Onboard User modal -->
{#if showOnboardModal}
  <div class="modal-backdrop" onclick={(e) => { if (e.target === e.currentTarget) showOnboardModal = false }}>
    <div class="modal-box">
      <div class="modal-title">Onboard User</div>
      <div class="modal-desc">Create a new system user. Requires scope.</div>
      <form onsubmit={(e) => { e.preventDefault(); handleOnboard() }}>
        <div class="mb-4">
          <label class="field-label">Name</label>
          <input bind:value={form.name} type="text" class="field-input" placeholder="Jane Smith" required>
        </div>
        <div class="mb-5">
          <label class="field-label">Email</label>
          <input bind:value={form.email} type="email" class="field-input" placeholder="jane@example.com" required>
        </div>
        <div class="flex gap-2 justify-end">
          <button type="button" onclick={() => showOnboardModal = false} class="btn btn-ghost">Cancel</button>
          <button type="submit" class="btn btn-primary" disabled={ui.loading}>Onboard User</button>
        </div>
      </form>
    </div>
  </div>
{/if}
