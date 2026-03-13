<script>
  import { viewData, pagination, ui } from '../../lib/store.svelte.js'
  import { loadMore, createLedgerTransaction } from '../../lib/actions.js'
  import { apiFetch } from '../../lib/api.js'

  const today = () => new Date().toISOString().split('T')[0]

  let showModal = $state(false)
  let accountOptions = $state([])
  let activeDropdown = $state(-1)
  let entryCounter = $state(1)

  let form = $state({
    currency: '',
    posting_date: '',
    value_date: '',
    remittance_information: '',
    metadata: { payment_type: '', external_ref: '', channel: 'api' },
  })
  let entries = $state([
    { _id: 0, account_id: '', direction: 'debit', amount: '', entry_type: 'principal' },
  ])

  let suggestions = $derived(
    activeDropdown >= 0
      ? accountOptions
          .filter(a => {
            const q = (entries[activeDropdown]?.account_id ?? '').toLowerCase()
            return q === '' || a.id.toLowerCase().includes(q) || (a.type ?? '').includes(q)
          })
          .slice(0, 8)
      : []
  )

  async function openModal() {
    form = {
      currency: '',
      posting_date: today(),
      value_date: today(),
      remittance_information: '',
      metadata: { payment_type: '', external_ref: '', channel: 'api' },
    }
    entries = [{ _id: 0, account_id: '', direction: 'debit', amount: '', entry_type: 'principal' }]
    entryCounter = 1
    activeDropdown = -1
    showModal = true
    try {
      const res = await apiFetch('GET', '/accounts/?limit=200')
      accountOptions = res.data.map(e => e.attributes)
    } catch { accountOptions = [] }
  }

  function addEntry() {
    entries = [...entries, { _id: entryCounter++, account_id: '', direction: 'credit', amount: '', entry_type: 'principal' }]
  }

  function removeEntry(idx) {
    entries = entries.filter((_, i) => i !== idx)
  }

  function selectAccount(idx, accountId) {
    entries[idx].account_id = accountId
    activeDropdown = -1
  }

  async function handleSubmit() {
    try {
      await createLedgerTransaction({
        currency: form.currency,
        posting_date: form.posting_date,
        value_date: form.value_date,
        remittance_information: form.remittance_information,
        metadata: {
          payment_type: form.metadata.payment_type || undefined,
          external_ref: form.metadata.external_ref || undefined,
          channel: form.metadata.channel || undefined,
        },
        entries: entries.map(e => ({
          account_id: e.account_id,
          direction: e.direction,
          amount: parseInt(e.amount, 10),
          entry_type: e.entry_type,
        })),
      })
      showModal = false
    } catch {}
  }

  // ── Detail drawer ────────────────────────────────────
  let drawerPosting = $state(null)
</script>

<div class="page-header">
  <div>
    <div class="page-title">Ledger</div>
    <div class="page-subtitle">Internal transfers and their ledger postings</div>
  </div>
  <button onclick={openModal} class="btn btn-primary btn-sm">
    <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
    Create Transaction
  </button>
</div>

<!-- Postings table -->
<div class="card overflow-hidden">
  <table class="data-table">
    <thead>
      <tr>
        <th>Transaction ID</th>
        <th>Account ID</th>
        <th>Direction</th>
        <th>Amount</th>
        <th>Currency</th>
        <th>Entry Type</th>
        <th>Posting Date</th>
        <th>Value Date</th>
        <th>Remittance Information</th>
      </tr>
    </thead>
    <tbody>
      {#if viewData.postings.length === 0 && !ui.loadingView}
        <tr><td colspan="9" class="text-center py-10 text-zinc-400 text-sm">No postings found</td></tr>
      {/if}
      {#each viewData.postings as p, i (i)}
        <tr onclick={() => drawerPosting = p} class="cursor-pointer">
          <td><span class="mono text-xs">{p.id}</span></td>
          <td><span class="mono text-xs">{p.account_id}</span></td>
          <td>
            <span class="badge" class:badge-red={p.direction === 'debit'} class:badge-green={p.direction === 'credit'}>
              {p.direction}
            </span>
          </td>
          <td class="font-semibold tabular-nums">{Number(p.amount).toLocaleString()}</td>
          <td><span class="badge badge-zinc">{p.currency?.toUpperCase()}</span></td>
          <td><span class="badge badge-zinc">{p.entry_type?.replace('_', ' ')}</span></td>
          <td class="text-zinc-500 text-xs tabular-nums">{p.posting_date}</td>
          <td class="text-zinc-500 text-xs tabular-nums">{p.value_date}</td>
          <td class="text-zinc-500 max-w-xs truncate">{p.remittance_information}</td>
        </tr>
      {/each}
    </tbody>
  </table>
  {#if ui.loadingView === 'postings'}
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

<!-- Posting detail drawer -->
{#if drawerPosting}
  <div class="drawer-backdrop" onclick={() => drawerPosting = null}></div>
  <div class="drawer-panel">
    <div class="drawer-header">
      <div class="drawer-title">Posting Details</div>
      <button onclick={() => drawerPosting = null} class="text-zinc-400 hover:text-zinc-700 transition-colors">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
      </button>
    </div>
    <div class="drawer-body">
      <div class="drawer-field">
        <div class="drawer-field-label">Transaction ID</div>
        <div class="font-mono text-xs bg-zinc-50 border border-zinc-200 rounded px-2.5 py-1.5 break-all select-all">{drawerPosting.id}</div>
      </div>
      <div class="drawer-field">
        <div class="drawer-field-label">Account ID</div>
        <div class="font-mono text-xs bg-zinc-50 border border-zinc-200 rounded px-2.5 py-1.5 break-all select-all">{drawerPosting.account_id}</div>
      </div>
      <div class="drawer-field">
        <div class="drawer-field-label">Direction</div>
        <div>
          <span class="badge" class:badge-red={drawerPosting.direction === 'debit'} class:badge-green={drawerPosting.direction === 'credit'}>
            {drawerPosting.direction}
          </span>
        </div>
      </div>
      <div class="drawer-field">
        <div class="drawer-field-label">Amount</div>
        <div class="drawer-field-value font-semibold tabular-nums text-lg">{Number(drawerPosting.amount).toLocaleString()}</div>
      </div>
      <div class="drawer-field">
        <div class="drawer-field-label">Currency</div>
        <div><span class="badge badge-zinc">{drawerPosting.currency?.toUpperCase()}</span></div>
      </div>
      <div class="drawer-field">
        <div class="drawer-field-label">Entry Type</div>
        <div><span class="badge badge-zinc">{drawerPosting.entry_type?.replace('_', ' ')}</span></div>
      </div>
      <div class="drawer-field">
        <div class="drawer-field-label">Posting Date</div>
        <div class="drawer-field-value tabular-nums">{drawerPosting.posting_date}</div>
      </div>
      <div class="drawer-field">
        <div class="drawer-field-label">Value Date</div>
        <div class="drawer-field-value tabular-nums">{drawerPosting.value_date}</div>
      </div>
      <div class="drawer-field">
        <div class="drawer-field-label">Remittance Information</div>
        <div class="drawer-field-value">{drawerPosting.remittance_information}</div>
      </div>
    </div>
  </div>
{/if}

<!-- Create Ledger Transaction modal -->
{#if showModal}
  <div class="modal-backdrop" onclick={(e) => { if (e.target === e.currentTarget) showModal = false }}>
    <div class="modal-box modal-box-lg">
      <div class="modal-title">Create Ledger Transaction</div>
      <div class="modal-desc">Submit a multi-entry ledger transaction. Debits and credits must balance per currency.</div>

      <form onsubmit={(e) => { e.preventDefault(); handleSubmit() }}>

        <div class="grid grid-cols-3 gap-3 mb-4">
          <div>
            <label class="field-label">Currency</label>
            <select bind:value={form.currency} class="field-input field-select" required>
              <option value="">Select...</option>
              <option value="chf">CHF</option>
              <option value="eur">EUR</option>
              <option value="gbp">GBP</option>
              <option value="jpy">JPY</option>
              <option value="usd">USD</option>
            </select>
          </div>
          <div>
            <label class="field-label">Posting Date</label>
            <input bind:value={form.posting_date} type="date" class="field-input" required>
          </div>
          <div>
            <label class="field-label">Value Date</label>
            <input bind:value={form.value_date} type="date" class="field-input" required>
          </div>
        </div>

        <div class="mb-4">
          <label class="field-label">Remittance Information <span class="text-zinc-400 font-normal">(optional)</span></label>
          <input bind:value={form.remittance_information} type="text" class="field-input" placeholder="Payment for services...">
        </div>

        <div class="grid grid-cols-3 gap-3 mb-5">
          <div>
            <label class="field-label">Payment Type</label>
            <select bind:value={form.metadata.payment_type} class="field-input field-select">
              <option value="">None</option>
              <option value="SEPA_CREDIT_TRANSFER">SEPA Credit Transfer</option>
              <option value="SWIFT_WIRE">SWIFT Wire</option>
              <option value="ACH">ACH</option>
              <option value="BOOK_TRANSFER">Book Transfer</option>
              <option value="INTERNAL_TRANSFER">Internal Transfer</option>
            </select>
          </div>
          <div>
            <label class="field-label">External Ref <span class="text-zinc-400 font-normal">(optional)</span></label>
            <input bind:value={form.metadata.external_ref} type="text" class="field-input" placeholder="ext-ref-123">
          </div>
          <div>
            <label class="field-label">Channel</label>
            <select bind:value={form.metadata.channel} class="field-input field-select">
              <option value="api">API</option>
              <option value="web">Web</option>
              <option value="batch">Batch</option>
              <option value="manual">Manual</option>
            </select>
          </div>
        </div>

        <div class="mb-2 flex items-center justify-between">
          <div class="text-sm font-semibold text-zinc-700">Entries</div>
          <button type="button" onclick={addEntry} class="btn btn-ghost btn-sm text-xs">
            <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
            Add entry
          </button>
        </div>

        <div class="space-y-2 mb-5">
          {#each entries as entry, i (entry._id)}
            <div class="border border-zinc-200 rounded-lg p-3 bg-zinc-50">
              <div class="grid gap-2" style="grid-template-columns: 1fr 90px 110px 120px 32px">

                <div class="relative">
                  <label class="field-label text-xs">Account ID</label>
                  <input
                    type="text"
                    value={entry.account_id}
                    oninput={(e) => { entry.account_id = e.target.value; activeDropdown = i }}
                    onfocus={() => activeDropdown = i}
                    onblur={() => setTimeout(() => { if (activeDropdown === i) activeDropdown = -1 }, 180)}
                    class="field-input font-mono text-xs"
                    placeholder="UUID"
                    required
                  >
                  {#if activeDropdown === i && suggestions.length > 0}
                    <div class="absolute top-full left-0 right-0 z-20 bg-white border border-zinc-200 rounded-md shadow-lg mt-0.5 max-h-48 overflow-y-auto">
                      {#each suggestions as acct (acct.id)}
                        <button
                          type="button"
                          class="w-full text-left px-3 py-2 hover:bg-zinc-50 border-b border-zinc-100 last:border-0"
                          onmousedown={(e) => { e.preventDefault(); selectAccount(i, acct.id) }}
                        >
                          <div class="font-mono text-xs text-zinc-800 break-all">{acct.id}</div>
                          <div class="text-xs text-zinc-400 mt-0.5">{acct.type?.replace('_', ' ')} · {(acct.currencies ?? []).map(c => c.toUpperCase()).join(', ')}</div>
                        </button>
                      {/each}
                    </div>
                  {/if}
                </div>

                <div>
                  <label class="field-label text-xs">Direction</label>
                  <select bind:value={entry.direction} class="field-input field-select text-xs" required>
                    <option value="debit">Debit</option>
                    <option value="credit">Credit</option>
                  </select>
                </div>

                <div>
                  <label class="field-label text-xs">Amount</label>
                  <input bind:value={entry.amount} type="number" min="1" class="field-input text-xs" placeholder="0" required>
                </div>

                <div>
                  <label class="field-label text-xs">Entry Type</label>
                  <select bind:value={entry.entry_type} class="field-input field-select text-xs" required>
                    <option value="principal">Principal</option>
                    <option value="settlement">Settlement</option>
                    <option value="transaction_fee">Transaction Fee</option>
                  </select>
                </div>

                <div class="flex items-end pb-0.5">
                  {#if entries.length > 1}
                    <button
                      type="button"
                      onclick={() => removeEntry(i)}
                      class="w-8 h-8 flex items-center justify-center text-zinc-400 hover:text-red-500 hover:bg-red-50 rounded transition-colors"
                      title="Remove entry"
                    >
                      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
                    </button>
                  {:else}
                    <div class="w-8"></div>
                  {/if}
                </div>

              </div>
            </div>
          {/each}
        </div>

        <div class="flex gap-2 justify-end">
          <button type="button" onclick={() => showModal = false} class="btn btn-ghost">Cancel</button>
          <button type="submit" class="btn btn-primary" disabled={ui.loading}>Create Transaction</button>
        </div>

      </form>
    </div>
  </div>
{/if}
