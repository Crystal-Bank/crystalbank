<script>
  import { viewData, pagination, ui } from '../../lib/store.svelte.js'
  import { loadMore, createCustomer } from '../../lib/actions.js'

  let showModal = $state(false)
  let form = $state({ name: '', type: '' })

  function openModal() {
    form = { name: '', type: '' }
    showModal = true
  }

  async function handleSubmit() {
    try {
      await createCustomer({ name: form.name, type: form.type })
      showModal = false
    } catch {}
  }
</script>

<div class="page-header">
  <div>
    <div class="page-title">Customers</div>
    <div class="page-subtitle">Onboarded customers and their types</div>
  </div>
  <button onclick={openModal} class="btn btn-primary btn-sm">
    <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
    Onboard Customer
  </button>
</div>

<div class="card overflow-hidden">
  <table class="data-table">
    <thead><tr><th>ID</th><th>Name</th><th>Type</th><th>Scope</th></tr></thead>
    <tbody>
      {#if viewData.customers.length === 0 && !ui.loadingView}
        <tr><td colspan="4" class="text-center py-10 text-zinc-400 text-sm">No customers found</td></tr>
      {/if}
      {#each viewData.customers as c (c.id)}
        <tr>
          <td><span class="mono text-xs">{c.id}</span></td>
          <td class="font-medium">{c.name}</td>
          <td><span class="badge" class:badge-blue={c.type === 'individual'} class:badge-amber={c.type !== 'individual'}>{c.type}</span></td>
          <td><span class="mono text-xs">{c.scope_id}</span></td>
        </tr>
      {/each}
    </tbody>
  </table>
  {#if ui.loadingView === 'customers'}
    <div class="flex justify-center py-6">
      <div class="animate-spin w-5 h-5 border-2 border-zinc-300 border-t-zinc-700 rounded-full"></div>
    </div>
  {/if}
  {#if pagination.hasMore.customers && !ui.loading}
    <div class="p-4 border-t border-zinc-100 flex justify-center">
      <button onclick={() => loadMore('customers')} class="btn btn-ghost btn-sm">Load more</button>
    </div>
  {/if}
</div>

{#if showModal}
  <div class="modal-backdrop" onclick={(e) => { if (e.target === e.currentTarget) showModal = false }}>
    <div class="modal-box">
      <div class="modal-title">Onboard Customer</div>
      <div class="modal-desc">Register a new customer in the system. Requires scope.</div>
      <form onsubmit={(e) => { e.preventDefault(); handleSubmit() }}>
        <div class="mb-4">
          <label class="field-label">Name</label>
          <input bind:value={form.name} type="text" class="field-input" placeholder="John Doe" required minlength="2">
        </div>
        <div class="mb-5">
          <label class="field-label">Customer Type</label>
          <select bind:value={form.type} class="field-input field-select" required>
            <option value="">Select type...</option>
            <option value="individual">Individual</option>
            <option value="business">Business</option>
          </select>
        </div>
        <div class="flex gap-2 justify-end">
          <button type="button" onclick={() => showModal = false} class="btn btn-ghost">Cancel</button>
          <button type="submit" class="btn btn-primary" disabled={ui.loading}>Onboard Customer</button>
        </div>
      </form>
    </div>
  </div>
{/if}
