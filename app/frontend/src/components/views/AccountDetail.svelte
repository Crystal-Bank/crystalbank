<script>
  import { ui } from '../../lib/store.svelte.js'
  import { apiFetch } from '../../lib/api.js'

  /** @type {{ account: object }} */
  let { account } = $props()

  // ── Postings state ───────────────────────────────────
  let postings = $state([])
  let hasMore = $state(false)
  let cursor = $state(null)
  let loadingPostings = $state(false)
  let drawerPosting = $state(null)

  async function loadPostings(reset = false) {
    if (loadingPostings) return
    loadingPostings = true
    try {
      let url = `/ledger/transactions/postings/?limit=20&account_id=${account.id}`
      if (!reset && cursor) url += `&cursor=${cursor}`
      const res = await apiFetch('GET', url)
      const items = res.data.map(e => e.attributes)
      postings = reset ? items : [...postings, ...items]
      hasMore = res.meta.has_more
      cursor = res.meta.next_cursor || null
    } catch {}
    loadingPostings = false
  }

  $effect(() => {
    postings = []
    hasMore = false
    cursor = null
    loadPostings(true)
  })
</script>

<div class="page-header">
  <div class="flex items-center gap-3">
    <button
      onclick={() => { window.location.hash = 'accounts' }}
      class="text-zinc-400 hover:text-zinc-700 transition-colors"
      title="Back to accounts"
    >
      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="15 18 9 12 15 6"/></svg>
    </button>
    <div>
      <div class="page-title">{account.name}</div>
      <div class="page-subtitle">Account details and transaction history</div>
    </div>
  </div>
</div>

<!-- Account metadata card -->
<div class="card p-5 mb-5">
  <div class="grid grid-cols-2 gap-x-8 gap-y-4 sm:grid-cols-3">
    <div>
      <div class="text-xs font-medium text-zinc-400 uppercase tracking-wide mb-1">Name</div>
      <div class="font-medium text-sm">{account.name}</div>
    </div>
    <div>
      <div class="text-xs font-medium text-zinc-400 uppercase tracking-wide mb-1">Type</div>
      <div>
        <span class="badge" class:badge-blue={account.type === 'checking'} class:badge-purple={account.type !== 'checking'}>
          {account.type?.replace('_', ' ')}
        </span>
      </div>
    </div>
    <div>
      <div class="text-xs font-medium text-zinc-400 uppercase tracking-wide mb-1">Currencies</div>
      <div class="flex gap-1 flex-wrap">
        {#each account.currencies ?? [] as c (c)}
          <span class="badge badge-zinc">{c.toUpperCase()}</span>
        {/each}
      </div>
    </div>
    <div class="col-span-2 sm:col-span-3">
      <div class="text-xs font-medium text-zinc-400 uppercase tracking-wide mb-1">Account ID</div>
      <div class="font-mono text-xs bg-zinc-50 border border-zinc-200 rounded px-2.5 py-1.5 break-all select-all w-fit">{account.id}</div>
    </div>
    <div class="col-span-2 sm:col-span-3">
      <div class="text-xs font-medium text-zinc-400 uppercase tracking-wide mb-1">Scope ID</div>
      <div class="font-mono text-xs bg-zinc-50 border border-zinc-200 rounded px-2.5 py-1.5 break-all select-all w-fit">{account.scope_id}</div>
    </div>
    {#if (account.customer_ids?.length ?? 0) > 0}
      <div class="col-span-2 sm:col-span-3">
        <div class="text-xs font-medium text-zinc-400 uppercase tracking-wide mb-1">Customer IDs</div>
        <div class="space-y-1">
          {#each account.customer_ids as cid (cid)}
            <div class="font-mono text-xs bg-zinc-50 border border-zinc-200 rounded px-2.5 py-1.5 break-all select-all w-fit">{cid}</div>
          {/each}
        </div>
      </div>
    {/if}
  </div>
</div>

<!-- Postings table -->
<div class="mb-3 text-sm font-semibold text-zinc-700">Transaction History</div>
<div class="card overflow-hidden">
  <table class="data-table">
    <thead>
      <tr>
        <th>ID</th>
        <th>Direction</th>
        <th>Amount</th>
        <th>Currency</th>
        <th>Entry Type</th>
        <th>Posting Date</th>
        <th>Value Date</th>
      </tr>
    </thead>
    <tbody>
      {#if postings.length === 0 && !loadingPostings}
        <tr><td colspan="7" class="text-center py-10 text-zinc-400 text-sm">No postings found for this account</td></tr>
      {/if}
      {#each postings as p, i (i)}
        <tr onclick={() => drawerPosting = p} class="cursor-pointer">
          <td><span class="mono text-xs">{p.id}</span></td>
          <td>
            <span class="badge" class:badge-red={p.direction?.toLowerCase() === 'debit'} class:badge-green={p.direction?.toLowerCase() === 'credit'}>
              {p.direction?.toLowerCase()}
            </span>
          </td>
          <td class="font-semibold tabular-nums">{Number(p.amount).toLocaleString()}</td>
          <td><span class="badge badge-zinc">{p.currency?.toUpperCase()}</span></td>
          <td><span class="badge badge-zinc">{p.entry_type?.toLowerCase().replaceAll('_', ' ')}</span></td>
          <td class="text-zinc-500 text-xs tabular-nums">{p.posting_date}</td>
          <td class="text-zinc-500 text-xs tabular-nums">{p.value_date}</td>
        </tr>
      {/each}
    </tbody>
  </table>
  {#if loadingPostings}
    <div class="flex justify-center py-6">
      <div class="animate-spin w-5 h-5 border-2 border-zinc-300 border-t-zinc-700 rounded-full"></div>
    </div>
  {/if}
  {#if hasMore && !loadingPostings}
    <div class="p-4 border-t border-zinc-100 flex justify-center">
      <button onclick={() => loadPostings()} class="btn btn-ghost btn-sm">Load more</button>
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
        <div class="drawer-field-label">Posting ID</div>
        <div class="font-mono text-xs bg-zinc-50 border border-zinc-200 rounded px-2.5 py-1.5 break-all select-all">{drawerPosting.id}</div>
      </div>
      <div class="drawer-field">
        <div class="drawer-field-label">Transaction ID</div>
        <div class="font-mono text-xs bg-zinc-50 border border-zinc-200 rounded px-2.5 py-1.5 break-all select-all">{drawerPosting.transaction_id}</div>
      </div>
      <div class="drawer-field">
        <div class="drawer-field-label">Account ID</div>
        <div class="font-mono text-xs bg-zinc-50 border border-zinc-200 rounded px-2.5 py-1.5 break-all select-all">{drawerPosting.account_id}</div>
      </div>
      <div class="drawer-field">
        <div class="drawer-field-label">Direction</div>
        <div>
          <span class="badge" class:badge-red={drawerPosting.direction?.toLowerCase() === 'debit'} class:badge-green={drawerPosting.direction?.toLowerCase() === 'credit'}>
            {drawerPosting.direction?.toLowerCase()}
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
        <div><span class="badge badge-zinc">{drawerPosting.entry_type?.toLowerCase().replaceAll('_', ' ')}</span></div>
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
