<script>
  import { viewData, pagination, ui, SUPPORTED_CURRENCIES } from '../../lib/store.svelte.js'
  import { loadMore, createAccount } from '../../lib/actions.js'
  import { apiFetch } from '../../lib/api.js'

  function openAccountDetail(account) {
    ui.selectedAccount = account
    ui.view = 'account_detail'
  }

  // ── Create modal ─────────────────────────────────────
  let showModal = $state(false)
  let form = $state({ name: '', type: '', selectedCurrencies: [], customerIds: [] })
  let customerOptions = $state([])
  let customerSearch = $state('')
  let showCustomerDropdown = $state(false)

  let customerSuggestions = $derived(
    customerOptions
      .filter(c => {
        if (form.customerIds.includes(c.id)) return false
        const q = customerSearch.toLowerCase()
        return q === '' || c.id.toLowerCase().includes(q) || c.name.toLowerCase().includes(q)
      })
      .slice(0, 8)
  )

  async function openModal() {
    form = { name: '', type: '', selectedCurrencies: [], customerIds: [] }
    customerSearch = ''
    showModal = true
    try {
      const res = await apiFetch('GET', '/customers/?limit=200')
      customerOptions = res.data.map(e => e.attributes)
    } catch { customerOptions = [] }
  }

  function toggleCurrency(c) {
    const idx = form.selectedCurrencies.indexOf(c)
    if (idx === -1) form.selectedCurrencies = [...form.selectedCurrencies, c]
    else form.selectedCurrencies = form.selectedCurrencies.filter(x => x !== c)
  }

  function addCustomer(customerId) {
    if (!form.customerIds.includes(customerId)) form.customerIds = [...form.customerIds, customerId]
    customerSearch = ''
    showCustomerDropdown = false
  }

  function removeCustomer(customerId) {
    form.customerIds = form.customerIds.filter(id => id !== customerId)
  }

  function getCustomerName(id) {
    return customerOptions.find(c => c.id === id)?.name ?? id
  }

  async function handleSubmit() {
    try {
      await createAccount({ name: form.name, type: form.type, currencies: form.selectedCurrencies, customerIds: form.customerIds })
      showModal = false
    } catch {}
  }

</script>

<div class="page-header">
  <div>
    <div class="page-title">Accounts</div>
    <div class="page-subtitle">Bank accounts and their owners</div>
  </div>
  <button onclick={openModal} class="btn btn-primary btn-sm">
    <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
    Open Account
  </button>
</div>

<div class="card overflow-hidden">
  <table class="data-table">
    <thead><tr><th>Name</th><th>ID</th><th>Type</th><th>Currencies</th><th>Customers</th><th>Scope</th><th>Status</th></tr></thead>
    <tbody>
      {#if viewData.accounts.length === 0 && !ui.loadingView}
        <tr><td colspan="7" class="text-center py-10 text-zinc-400 text-sm">No accounts found</td></tr>
      {/if}
      {#each viewData.accounts as a (a.id)}
        <tr onclick={() => a.status !== 'pending' && openAccountDetail(a)} class:cursor-pointer={a.status !== 'pending'} class:opacity-60={a.status === 'pending'}>
          <td class="font-medium">{a.name}</td>
          <td><span class="mono text-xs">{a.id}</span></td>
          <td><span class="badge" class:badge-blue={a.type === 'checking'} class:badge-purple={a.type !== 'checking'}>{a.type?.replace('_', ' ')}</span></td>
          <td>
            <div class="flex gap-1 flex-wrap">
              {#each a.currencies ?? [] as c (c)}
                <span class="badge badge-zinc">{c.toUpperCase()}</span>
              {/each}
            </div>
          </td>
          <td class="text-xs text-zinc-500">{(a.customer_ids?.length ?? 0)} owner(s)</td>
          <td><span class="mono text-xs">{a.scope_id}</span></td>
          <td>
            {#if a.status === 'pending'}
              <span class="badge badge-amber">pending</span>
            {:else}
              <span class="badge badge-green">active</span>
            {/if}
          </td>
        </tr>
      {/each}
    </tbody>
  </table>
  {#if ui.loadingView === 'accounts'}
    <div class="flex justify-center py-6">
      <div class="animate-spin w-5 h-5 border-2 border-zinc-300 border-t-zinc-700 rounded-full"></div>
    </div>
  {/if}
  {#if pagination.hasMore.accounts && !ui.loading}
    <div class="p-4 border-t border-zinc-100 flex justify-center">
      <button onclick={() => loadMore('accounts')} class="btn btn-ghost btn-sm">Load more</button>
    </div>
  {/if}
</div>

<!-- Open Account modal -->
{#if showModal}
  <div class="modal-backdrop" onclick={(e) => { if (e.target === e.currentTarget) showModal = false }}>
    <div class="modal-box">
      <div class="modal-title">Open Account</div>
      <div class="modal-desc">Request the opening of a new bank account. Requires scope.</div>
      <form onsubmit={(e) => { e.preventDefault(); handleSubmit() }}>
        <div class="mb-4">
          <label class="field-label">Account Name</label>
          <input type="text" bind:value={form.name} class="field-input" placeholder="e.g. Main Operating Account" required>
        </div>
        <div class="mb-4">
          <label class="field-label">Account Type</label>
          <select bind:value={form.type} class="field-input field-select" required>
            <option value="">Select type...</option>
            <option value="checking">Checking</option>
            <option value="overnight_money">Overnight Money</option>
            <option value="savings">Savings</option>
            <option value="card">Card</option>
          </select>
        </div>
        <div class="mb-4">
          <label class="field-label">Currencies</label>
          <div class="checkbox-grid flex gap-4 flex-wrap mt-1">
            {#each SUPPORTED_CURRENCIES as c (c)}
              <label class="checkbox-item">
                <input type="checkbox" checked={form.selectedCurrencies.includes(c)} onchange={() => toggleCurrency(c)}>
                <span class="font-mono text-sm">{c.toUpperCase()}</span>
              </label>
            {/each}
          </div>
          <div class="field-hint">Select one or more supported currencies</div>
        </div>
        <div class="mb-5">
          <label class="field-label">Customer IDs</label>
          {#if form.customerIds.length > 0}
            <div class="flex flex-wrap gap-1.5 mb-2">
              {#each form.customerIds as id (id)}
                <span class="inline-flex items-center gap-1 bg-zinc-100 border border-zinc-200 rounded px-2 py-0.5 text-xs">
                  <span class="font-mono text-zinc-700">{getCustomerName(id)}</span>
                  <button type="button" onclick={() => removeCustomer(id)} class="text-zinc-400 hover:text-red-500 leading-none">&times;</button>
                </span>
              {/each}
            </div>
          {/if}
          <div class="relative">
            <input
              type="text"
              bind:value={customerSearch}
              onfocus={() => showCustomerDropdown = true}
              onblur={() => setTimeout(() => { showCustomerDropdown = false }, 180)}
              oninput={() => showCustomerDropdown = true}
              class="field-input"
              placeholder="Search customers by name or ID..."
            >
            {#if showCustomerDropdown && customerSuggestions.length > 0}
              <div class="absolute top-full left-0 right-0 z-20 bg-white border border-zinc-200 rounded-md shadow-lg mt-0.5 max-h-48 overflow-y-auto">
                {#each customerSuggestions as c (c.id)}
                  <button
                    type="button"
                    class="w-full text-left px-3 py-2 hover:bg-zinc-50 border-b border-zinc-100 last:border-0"
                    onmousedown={(e) => { e.preventDefault(); addCustomer(c.id) }}
                  >
                    <div class="font-medium text-xs text-zinc-800">{c.name}</div>
                    <div class="font-mono text-xs text-zinc-400 mt-0.5">{c.id}</div>
                  </button>
                {/each}
              </div>
            {/if}
          </div>
          <div class="field-hint">Search and select customer(s) to assign as account owners</div>
        </div>
        <div class="flex gap-2 justify-end">
          <button type="button" onclick={() => showModal = false} class="btn btn-ghost">Cancel</button>
          <button type="submit" class="btn btn-primary" disabled={ui.loading}>Open Account</button>
        </div>
      </form>
    </div>
  </div>
{/if}
