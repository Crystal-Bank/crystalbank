<script>
  import { viewData, pagination, ui, SUPPORTED_CURRENCIES } from '../../lib/store.svelte.js'
  import { loadMore, createAccount } from '../../lib/actions.js'

  let showModal = $state(false)
  let form = $state({ type: '', customerIds: '', selectedCurrencies: [] })

  function openModal() {
    form = { type: '', customerIds: '', selectedCurrencies: [] }
    showModal = true
  }

  function toggleCurrency(c) {
    const idx = form.selectedCurrencies.indexOf(c)
    if (idx === -1) form.selectedCurrencies = [...form.selectedCurrencies, c]
    else form.selectedCurrencies = form.selectedCurrencies.filter(x => x !== c)
  }

  async function handleSubmit() {
    try {
      await createAccount({ type: form.type, currencies: form.selectedCurrencies, customerIds: form.customerIds })
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
    <thead><tr><th>ID</th><th>Type</th><th>Currencies</th><th>Customers</th><th>Scope</th></tr></thead>
    <tbody>
      {#if viewData.accounts.length === 0 && !ui.loading}
        <tr><td colspan="5" class="text-center py-10 text-zinc-400 text-sm">No accounts found</td></tr>
      {/if}
      {#each viewData.accounts as a (a.id)}
        <tr>
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

{#if showModal}
  <div class="modal-backdrop" onclick={(e) => { if (e.target === e.currentTarget) showModal = false }}>
    <div class="modal-box">
      <div class="modal-title">Open Account</div>
      <div class="modal-desc">Request the opening of a new bank account. Requires scope.</div>
      <form onsubmit={(e) => { e.preventDefault(); handleSubmit() }}>
        <div class="mb-4">
          <label class="field-label">Account Type</label>
          <select bind:value={form.type} class="field-input field-select" required>
            <option value="">Select type...</option>
            <option value="checking">Checking</option>
            <option value="overnight_money">Overnight Money</option>
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
          <textarea bind:value={form.customerIds} class="field-input" rows="2" placeholder="One UUID per line..."></textarea>
          <div class="field-hint">One customer UUID per line</div>
        </div>
        <div class="flex gap-2 justify-end">
          <button type="button" onclick={() => showModal = false} class="btn btn-ghost">Cancel</button>
          <button type="submit" class="btn btn-primary" disabled={ui.loading}>Open Account</button>
        </div>
      </form>
    </div>
  </div>
{/if}
