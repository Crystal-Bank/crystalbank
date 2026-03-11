<script>
  import { viewData, pagination, ui } from '../../lib/store.svelte.js'
  import { loadMore, initiateTransfer } from '../../lib/actions.js'

  let activeTab = $state('transfers')
  let showModal = $state(false)
  let form = $state({ debtor_account_id: '', creditor_account_id: '', amount: '', currency: '', remittance_information: '' })

  // Deduplicate postings into transfer-level rows (debtor+creditor+amount+currency+memo)
  let transfers = $derived.by(() => {
    const seen = new Map()
    for (const p of viewData.postings) {
      const key = `${p.debtor_account_id}|${p.creditor_account_id}|${p.amount}|${p.currency}|${p.remittance_information}`
      if (!seen.has(key)) seen.set(key, p)
    }
    return Array.from(seen.values())
  })

  function openModal() {
    form = { debtor_account_id: '', creditor_account_id: '', amount: '', currency: '', remittance_information: '' }
    showModal = true
  }

  async function handleSubmit() {
    try {
      await initiateTransfer({
        amount: form.amount,
        creditor_account_id: form.creditor_account_id,
        currency: form.currency,
        debtor_account_id: form.debtor_account_id,
        remittance_information: form.remittance_information,
      })
      showModal = false
    } catch {}
  }
</script>

<div class="page-header">
  <div>
    <div class="page-title">Ledger</div>
    <div class="page-subtitle">Internal transfers and their ledger postings</div>
  </div>
  <button onclick={openModal} class="btn btn-primary btn-sm">
    <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
    Initiate Transfer
  </button>
</div>

<!-- Tabs -->
<div class="flex gap-1 mb-4 border-b border-zinc-200">
  <button
    onclick={() => activeTab = 'transfers'}
    class="px-4 py-2 text-sm font-medium border-b-2 -mb-px transition-colors"
    class:border-zinc-900={activeTab === 'transfers'}
    class:text-zinc-900={activeTab === 'transfers'}
    class:border-transparent={activeTab !== 'transfers'}
    class:text-zinc-500={activeTab !== 'transfers'}
  >
    Ledger Transactions
  </button>
  <button
    onclick={() => activeTab = 'postings'}
    class="px-4 py-2 text-sm font-medium border-b-2 -mb-px transition-colors"
    class:border-zinc-900={activeTab === 'postings'}
    class:text-zinc-900={activeTab === 'postings'}
    class:border-transparent={activeTab !== 'postings'}
    class:text-zinc-500={activeTab !== 'postings'}
  >
    Postings
  </button>
</div>

<!-- Ledger Transactions tab -->
{#if activeTab === 'transfers'}
  <div class="card overflow-hidden">
    <table class="data-table">
      <thead>
        <tr>
          <th>Amount</th>
          <th>Currency</th>
          <th>Debtor Account ID</th>
          <th>Creditor Account ID</th>
          <th>Remittance Information</th>
        </tr>
      </thead>
      <tbody>
        {#if transfers.length === 0 && !ui.loading}
          <tr><td colspan="5" class="text-center py-10 text-zinc-400 text-sm">No transactions found</td></tr>
        {/if}
        {#each transfers as t (t.debtor_account_id + t.creditor_account_id + t.amount + t.currency)}
          <tr>
            <td class="font-semibold tabular-nums">{Number(t.amount).toLocaleString()}</td>
            <td><span class="badge badge-zinc">{t.currency?.toUpperCase()}</span></td>
            <td><span class="mono text-xs">{t.debtor_account_id}</span></td>
            <td><span class="mono text-xs">{t.creditor_account_id}</span></td>
            <td class="text-zinc-500 max-w-xs truncate">{t.remittance_information}</td>
          </tr>
        {/each}
      </tbody>
    </table>
    {#if ui.loading && ui.view === 'postings'}
      <div class="flex justify-center py-6">
        <div class="animate-spin w-5 h-5 border-2 border-zinc-300 border-t-zinc-700 rounded-full"></div>
      </div>
    {/if}
    {#if pagination.hasMore.postings && !ui.loading}
      <div class="p-4 border-t border-zinc-100 flex justify-center">
        <button onclick={() => loadMore('postings')} class="btn btn-ghost btn-sm">Load more</button>
      </div>
    {/if}
  </div>
{/if}

<!-- Postings tab -->
{#if activeTab === 'postings'}
  <div class="card overflow-hidden">
    <table class="data-table">
      <thead>
        <tr>
          <th>Posting ID</th>
          <th>Account ID</th>
          <th>Amount</th>
          <th>Currency</th>
          <th>Debtor Account ID</th>
          <th>Creditor Account ID</th>
          <th>Remittance Information</th>
        </tr>
      </thead>
      <tbody>
        {#if viewData.postings.length === 0 && !ui.loading}
          <tr><td colspan="7" class="text-center py-10 text-zinc-400 text-sm">No postings found</td></tr>
        {/if}
        {#each viewData.postings as p (p.id)}
          <tr>
            <td><span class="mono text-xs">{p.id}</span></td>
            <td><span class="mono text-xs">{p.account_id}</span></td>
            <td class="font-semibold tabular-nums">{Number(p.amount).toLocaleString()}</td>
            <td><span class="badge badge-zinc">{p.currency?.toUpperCase()}</span></td>
            <td><span class="mono text-xs">{p.debtor_account_id}</span></td>
            <td><span class="mono text-xs">{p.creditor_account_id}</span></td>
            <td class="text-zinc-500 max-w-xs truncate">{p.remittance_information}</td>
          </tr>
        {/each}
      </tbody>
    </table>
    {#if ui.loading && ui.view === 'postings'}
      <div class="flex justify-center py-6">
        <div class="animate-spin w-5 h-5 border-2 border-zinc-300 border-t-zinc-700 rounded-full"></div>
      </div>
    {/if}
    {#if pagination.hasMore.postings && !ui.loading}
      <div class="p-4 border-t border-zinc-100 flex justify-center">
        <button onclick={() => loadMore('postings')} class="btn btn-ghost btn-sm">Load more</button>
      </div>
    {/if}
  </div>
{/if}

{#if showModal}
  <div class="modal-backdrop" onclick={(e) => { if (e.target === e.currentTarget) showModal = false }}>
    <div class="modal-box">
      <div class="modal-title">Initiate Transfer</div>
      <div class="modal-desc">Move funds between two accounts. Requires scope.</div>
      <form onsubmit={(e) => { e.preventDefault(); handleSubmit() }}>
        <div class="mb-4">
          <label class="field-label">Debtor Account ID</label>
          <input bind:value={form.debtor_account_id} type="text" class="field-input font-mono text-sm" placeholder="UUID" required>
          <div class="field-hint">The account funds are taken from</div>
        </div>
        <div class="mb-4">
          <label class="field-label">Creditor Account ID</label>
          <input bind:value={form.creditor_account_id} type="text" class="field-input font-mono text-sm" placeholder="UUID" required>
          <div class="field-hint">The account funds are sent to</div>
        </div>
        <div class="mb-4">
          <div class="flex gap-3">
            <div class="flex-1">
              <label class="field-label">Amount</label>
              <input bind:value={form.amount} type="number" min="1" class="field-input" placeholder="100" required>
            </div>
            <div class="w-32">
              <label class="field-label">Currency</label>
              <select bind:value={form.currency} class="field-input field-select" required>
                <option value="">Pick...</option>
                <option value="chf">CHF</option>
                <option value="eur">EUR</option>
                <option value="gbp">GBP</option>
                <option value="jpy">JPY</option>
                <option value="usd">USD</option>
              </select>
            </div>
          </div>
        </div>
        <div class="mb-5">
          <label class="field-label">Remittance Information</label>
          <input bind:value={form.remittance_information} type="text" class="field-input" placeholder="Payment for services..." required>
        </div>
        <div class="flex gap-2 justify-end">
          <button type="button" onclick={() => showModal = false} class="btn btn-ghost">Cancel</button>
          <button type="submit" class="btn btn-primary" disabled={ui.loading}>Initiate Transfer</button>
        </div>
      </form>
    </div>
  </div>
{/if}
