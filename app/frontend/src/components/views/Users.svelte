<script>
  import { viewData, pagination, ui } from '../../lib/store.svelte.js'
  import { loadMore, createUser } from '../../lib/actions.js'

  let showModal = $state(false)
  let form = $state({ name: '', email: '' })

  function openModal() {
    form = { name: '', email: '' }
    showModal = true
  }

  async function handleSubmit() {
    try {
      await createUser({ name: form.name, email: form.email })
      showModal = false
    } catch {}
  }
</script>

<div class="page-header">
  <div>
    <div class="page-title">Users</div>
    <div class="page-subtitle">System users with assigned roles</div>
  </div>
  <button onclick={openModal} class="btn btn-primary btn-sm">
    <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
    Onboard User
  </button>
</div>

<div class="card overflow-hidden">
  <table class="data-table">
    <thead><tr><th>ID</th><th>Name</th><th>Email</th><th>Scope</th></tr></thead>
    <tbody>
      {#if viewData.users.length === 0 && !ui.loading}
        <tr><td colspan="4" class="text-center py-10 text-zinc-400 text-sm">No users found</td></tr>
      {/if}
      {#each viewData.users as u (u.id)}
        <tr>
          <td><span class="mono text-xs">{u.id}</span></td>
          <td class="font-medium">{u.name}</td>
          <td class="text-zinc-500">{u.email}</td>
          <td><span class="mono text-xs">{u.scope_id}</span></td>
        </tr>
      {/each}
    </tbody>
  </table>
  {#if ui.loading && ui.view === 'users'}
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

{#if showModal}
  <div class="modal-backdrop" onclick={(e) => { if (e.target === e.currentTarget) showModal = false }}>
    <div class="modal-box">
      <div class="modal-title">Onboard User</div>
      <div class="modal-desc">Create a new system user. Requires scope.</div>
      <form onsubmit={(e) => { e.preventDefault(); handleSubmit() }}>
        <div class="mb-4">
          <label class="field-label">Name</label>
          <input bind:value={form.name} type="text" class="field-input" placeholder="Jane Smith" required>
        </div>
        <div class="mb-5">
          <label class="field-label">Email</label>
          <input bind:value={form.email} type="email" class="field-input" placeholder="jane@example.com" required>
        </div>
        <div class="flex gap-2 justify-end">
          <button type="button" onclick={() => showModal = false} class="btn btn-ghost">Cancel</button>
          <button type="submit" class="btn btn-primary" disabled={ui.loading}>Onboard User</button>
        </div>
      </form>
    </div>
  </div>
{/if}
