<script>
  import { viewData, pagination, ui } from '../../lib/store.svelte.js'
  import { loadMore, createScope } from '../../lib/actions.js'
  import { shortId } from '../../lib/utils.js'

  let showModal = $state(false)
  let form = $state({ name: '', parent_scope_id: '' })

  function openModal() {
    form = { name: '', parent_scope_id: '' }
    showModal = true
  }

  async function handleSubmit() {
    try {
      await createScope({ name: form.name, parent_scope_id: form.parent_scope_id })
      showModal = false
    } catch {}
  }
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
    <thead><tr><th>ID</th><th>Name</th><th>Parent Scope</th><th>Scope ID</th></tr></thead>
    <tbody>
      {#if viewData.scopes.length === 0 && !ui.loading}
        <tr><td colspan="4" class="text-center py-10 text-zinc-400 text-sm">No scopes found</td></tr>
      {/if}
      {#each viewData.scopes as s (s.id)}
        <tr>
          <td><span class="mono">{shortId(s.id)}</span></td>
          <td class="font-medium">{s.name}</td>
          <td>
            {#if s.parent_scope_id}
              <span class="mono text-xs">{shortId(s.parent_scope_id)}</span>
            {:else}
              <span class="text-zinc-400 text-xs">Root</span>
            {/if}
          </td>
          <td><span class="mono text-xs">{shortId(s.scope_id)}</span></td>
        </tr>
      {/each}
    </tbody>
  </table>
  {#if ui.loading && ui.view === 'scopes'}
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
          <input bind:value={form.parent_scope_id} type="text" class="field-input font-mono text-sm" placeholder="UUID of parent scope...">
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
