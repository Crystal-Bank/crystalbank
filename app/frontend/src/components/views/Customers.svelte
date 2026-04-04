<script>
  import { viewData, pagination, ui } from '../../lib/store.svelte.js'
  import { loadMore, createCustomer } from '../../lib/actions.js'

  let showModal = $state(false)
  let form = $state({ name: '', type: '' })
  let drawerCustomer = $state(null)

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
    <thead><tr><th>ID</th><th>Name</th><th>Type</th><th>Status</th><th>Scope</th></tr></thead>
    <tbody>
      {#if viewData.customers.length === 0 && !ui.loadingView}
        <tr><td colspan="5" class="text-center py-10 text-zinc-400 text-sm">No customers found</td></tr>
      {/if}
      {#each viewData.customers as c (c.id)}
        <tr onclick={() => drawerCustomer = c} class="cursor-pointer">
          <td><span class="mono text-xs">{c.id}</span></td>
          <td class="font-medium">{c.name}</td>
          <td><span class="badge" class:badge-blue={c.type === 'individual'} class:badge-amber={c.type !== 'individual'}>{c.type}</span></td>
          <td>
            <span class="badge" class:badge-green={c.status === 'active'} class:badge-amber={c.status === 'pending'} class:badge-zinc={c.status !== 'active' && c.status !== 'pending'}>
              {c.status}
            </span>
          </td>
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

<!-- Customer detail drawer -->
{#if drawerCustomer}
  <div class="drawer-backdrop" onclick={() => drawerCustomer = null}></div>
  <div class="drawer-panel">
    <div class="drawer-header">
      <div class="drawer-title">Customer Details</div>
      <button onclick={() => drawerCustomer = null} class="text-zinc-400 hover:text-zinc-700 transition-colors">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
      </button>
    </div>
    <div class="drawer-body">
      <div class="drawer-field">
        <div class="drawer-field-label">ID</div>
        <div class="font-mono text-xs bg-zinc-50 border border-zinc-200 rounded px-2.5 py-1.5 break-all select-all">{drawerCustomer.id}</div>
      </div>
      <div class="drawer-field">
        <div class="drawer-field-label">Name</div>
        <div class="drawer-field-value font-medium">{drawerCustomer.name}</div>
      </div>
      <div class="drawer-field">
        <div class="drawer-field-label">Type</div>
        <div>
          <span class="badge" class:badge-blue={drawerCustomer.type === 'individual'} class:badge-amber={drawerCustomer.type !== 'individual'}>
            {drawerCustomer.type}
          </span>
        </div>
      </div>
      <div class="drawer-field">
        <div class="drawer-field-label">Status</div>
        <div>
          <span class="badge" class:badge-green={drawerCustomer.status === 'active'} class:badge-amber={drawerCustomer.status === 'pending'} class:badge-zinc={drawerCustomer.status !== 'active' && drawerCustomer.status !== 'pending'}>
            {drawerCustomer.status}
          </span>
        </div>
      </div>
      <div class="drawer-field">
        <div class="drawer-field-label">Scope ID</div>
        <div class="font-mono text-xs bg-zinc-50 border border-zinc-200 rounded px-2.5 py-1.5 break-all select-all">{drawerCustomer.scope_id}</div>
      </div>
    </div>
  </div>
{/if}

<!-- Onboard Customer modal -->
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
