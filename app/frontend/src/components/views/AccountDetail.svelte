<script>
  import { onMount } from 'svelte'
  import { ui } from '../../lib/store.svelte.js'
  import { apiFetch } from '../../lib/api.js'
  import { requestBlock, requestUnblock, switchView } from '../../lib/actions.js'
  import { shortId, formatDate } from '../../lib/utils.js'

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

  // ── Blocks state ─────────────────────────────────────
  let blocks = $state(null)
  let loadingBlocks = $state(false)
  let showBlockModal = $state(false)
  let blockForm = $state({ block_type: 'compliance_block', reason: '' })
  let pendingRemoval = $state(null)
  let removalReason = $state('')
  let lastRequest = $state(null)

  async function loadBlocks() {
    loadingBlocks = true
    try {
      blocks = await apiFetch('GET', `/accounts/${account.id}/blocks`)
    } catch {}
    loadingBlocks = false
  }

  async function submitBlock() {
    try {
      const res = await requestBlock(account.id, blockForm.block_type, blockForm.reason || null)
      lastRequest = res
      showBlockModal = false
      blockForm = { block_type: 'compliance_block', reason: '' }
      await loadBlocks()
    } catch {}
  }

  async function submitUnblock() {
    try {
      const res = await requestUnblock(account.id, pendingRemoval.block_type, removalReason || null)
      lastRequest = res
      pendingRemoval = null
      removalReason = ''
      await loadBlocks()
    } catch {}
  }

  const BLOCK_TYPE_LABELS = {
    compliance_block:    'Compliance Block',
    operations_block:    'Operations Block',
    generic_debit_block: 'Generic Debit Block',
    generic_credit_block:'Generic Credit Block',
    generic_full_block:  'Generic Full Block',
  }

  const BLOCK_TYPE_EFFECT = {
    compliance_block:    'Full',
    generic_full_block:  'Full',
    operations_block:    'Debit',
    generic_debit_block: 'Debit',
    generic_credit_block:'Credit',
  }

  function effectBadge(blockType) {
    const e = BLOCK_TYPE_EFFECT[blockType]
    if (e === 'Full')  return 'badge-red'
    if (e === 'Debit') return 'badge-amber'
    return 'badge-amber'
  }

  onMount(() => {
    loadPostings(true)
    loadBlocks()
  })
</script>

<div class="page-header">
  <div class="flex items-center gap-3">
    <button
      onclick={() => { ui.view = 'accounts'; ui.selectedAccount = null }}
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

<!-- ── Block Status ──────────────────────────────────── -->
<div class="flex items-center justify-between mb-3">
  <div class="flex items-center gap-2">
    <span class="text-sm font-semibold text-zinc-700">Block Status</span>
    {#if blocks}
      {#if blocks.effective_block === 'full_block'}
        <span class="badge badge-red">Full Block</span>
      {:else if blocks.effective_block === 'debit_block'}
        <span class="badge badge-amber">Debit Block</span>
      {:else if blocks.effective_block === 'credit_block'}
        <span class="badge badge-amber">Credit Block</span>
      {:else}
        <span class="badge badge-green">No blocks active</span>
      {/if}
    {/if}
  </div>
  <button
    onclick={() => showBlockModal = true}
    disabled={!blocks}
    class="btn btn-sm btn-primary"
  >
    Request Block
  </button>
</div>

<div class="card overflow-hidden mb-5">
  {#if loadingBlocks && !blocks}
    <div class="flex justify-center py-6">
      <div class="animate-spin w-5 h-5 border-2 border-zinc-300 border-t-zinc-700 rounded-full"></div>
    </div>
  {:else if blocks && blocks.blocks.length > 0}
    <table class="data-table">
      <thead>
        <tr>
          <th>Block Type</th>
          <th>Effect</th>
          <th>Applied At</th>
          <th>Applied By</th>
          <th>Reason</th>
          <th></th>
        </tr>
      </thead>
      <tbody>
        {#each blocks.blocks as b (b.block_type)}
          <tr>
            <td class="font-medium">{BLOCK_TYPE_LABELS[b.block_type] ?? b.block_type}</td>
            <td>
              <span class="badge {effectBadge(b.block_type)}">{BLOCK_TYPE_EFFECT[b.block_type] ?? '—'}</span>
            </td>
            <td class="text-zinc-500 text-xs tabular-nums">{formatDate(b.applied_at)}</td>
            <td><span class="mono text-xs">{shortId(b.applied_by)}</span></td>
            <td class="text-zinc-500 text-sm">{b.reason ?? '—'}</td>
            <td>
              <button
                onclick={() => { pendingRemoval = b; removalReason = '' }}
                class="btn btn-sm btn-ghost text-red-600 hover:text-red-700"
              >
                Request Removal
              </button>
            </td>
          </tr>
        {/each}
      </tbody>
    </table>
  {:else if blocks}
    <div class="py-8 text-center text-sm text-zinc-400">No active block causes</div>
  {/if}
</div>

<!-- ── Transaction History ───────────────────────────── -->
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

<!-- ── Request Block modal ──────────────────────────── -->
{#if showBlockModal}
  <div class="modal-backdrop" onclick={(e) => { if (e.target === e.currentTarget) showBlockModal = false }}>
    <div class="modal-box">
      <div class="modal-title">Request Block</div>
      <div class="modal-desc">The block will not take effect until approved by a user with the blocking approval permission.</div>
      <form onsubmit={(e) => { e.preventDefault(); submitBlock() }}>
        <div class="mb-4">
          <label class="field-label" for="block-type">Block Type</label>
          <select id="block-type" bind:value={blockForm.block_type} class="field-select">
            <option value="compliance_block">Compliance Block — Full Block</option>
            <option value="generic_full_block">Generic Full Block — Full Block</option>
            <option value="operations_block">Operations Block — Debit Block</option>
            <option value="generic_debit_block">Generic Debit Block — Debit Block</option>
            <option value="generic_credit_block">Generic Credit Block — Credit Block</option>
          </select>
        </div>
        <div class="mb-5">
          <label class="field-label" for="block-reason">Reason <span class="text-zinc-400 font-normal">(optional)</span></label>
          <textarea
            id="block-reason"
            bind:value={blockForm.reason}
            class="field-input resize-none"
            rows="2"
            placeholder="e.g. AML investigation"
          ></textarea>
        </div>
        <div class="flex justify-end gap-2">
          <button type="button" onclick={() => showBlockModal = false} class="btn btn-ghost">Cancel</button>
          <button type="submit" class="btn btn-primary" disabled={ui.loading}>Request Block</button>
        </div>
      </form>
    </div>
  </div>
{/if}

<!-- ── Request Removal drawer ───────────────────────── -->
{#if pendingRemoval}
  <div class="drawer-backdrop" onclick={() => { pendingRemoval = null; removalReason = '' }}></div>
  <div class="drawer-panel">
    <div class="drawer-header">
      <div class="drawer-title">Request Removal</div>
      <button onclick={() => { pendingRemoval = null; removalReason = '' }} class="text-zinc-400 hover:text-zinc-700 transition-colors">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
      </button>
    </div>
    <div class="drawer-body">
      <div class="drawer-field">
        <div class="drawer-field-label">Block Type</div>
        <div class="font-medium">{BLOCK_TYPE_LABELS[pendingRemoval.block_type] ?? pendingRemoval.block_type}</div>
      </div>
      <div class="drawer-field">
        <div class="drawer-field-label">Current Effect</div>
        <span class="badge {effectBadge(pendingRemoval.block_type)}">{BLOCK_TYPE_EFFECT[pendingRemoval.block_type]}</span>
      </div>
      <div class="drawer-field">
        <div class="drawer-field-label">Applied At</div>
        <div class="drawer-field-value">{formatDate(pendingRemoval.applied_at)}</div>
      </div>
      {#if pendingRemoval.reason}
        <div class="drawer-field">
          <div class="drawer-field-label">Original Reason</div>
          <div class="drawer-field-value">{pendingRemoval.reason}</div>
        </div>
      {/if}
      <div class="mb-4">
        <label class="field-label" for="removal-reason">Reason <span class="text-zinc-400 font-normal">(optional)</span></label>
        <input id="removal-reason" bind:value={removalReason} type="text" class="field-input" placeholder="e.g. Investigation concluded" />
      </div>
      <p class="text-xs text-zinc-400">The removal will not take effect until approved by a user with the unblocking approval permission.</p>
    </div>
    <div class="drawer-footer">
      <button onclick={() => { pendingRemoval = null; removalReason = '' }} class="btn btn-ghost">Cancel</button>
      <button onclick={submitUnblock} class="btn btn-danger" disabled={ui.loading}>Request Removal</button>
    </div>
  </div>
{/if}

<!-- ── Approval reference drawer ────────────────────── -->
{#if lastRequest}
  <div class="drawer-backdrop" onclick={() => lastRequest = null}></div>
  <div class="drawer-panel">
    <div class="drawer-header">
      <div class="drawer-title">Request Submitted</div>
      <button onclick={() => lastRequest = null} class="text-zinc-400 hover:text-zinc-700 transition-colors">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
      </button>
    </div>
    <div class="drawer-body">
      <div class="mb-4 p-3 bg-amber-50 border border-amber-200 rounded text-sm text-amber-800">
        The request is pending approval. Go to Approvals to sign it off.
      </div>
      <div class="drawer-field">
        <div class="drawer-field-label">Approval ID</div>
        <div class="font-mono text-xs bg-zinc-50 border border-zinc-200 rounded px-2.5 py-1.5 break-all select-all">{lastRequest.approval_id}</div>
      </div>
      <div class="drawer-field">
        <div class="drawer-field-label">Block Request ID</div>
        <div class="font-mono text-xs bg-zinc-50 border border-zinc-200 rounded px-2.5 py-1.5 break-all select-all">{lastRequest.block_request_id}</div>
      </div>
      <div class="drawer-field">
        <div class="drawer-field-label">Block Type</div>
        <div>{BLOCK_TYPE_LABELS[lastRequest.block_type] ?? lastRequest.block_type}</div>
      </div>
      <div class="drawer-field">
        <div class="drawer-field-label">Action</div>
        <span class="badge" class:badge-red={lastRequest.action === 'apply'} class:badge-green={lastRequest.action === 'remove'}>
          {lastRequest.action}
        </span>
      </div>
      <div class="drawer-field">
        <div class="drawer-field-label">Status</div>
        <span class="badge badge-amber">{lastRequest.status?.replace('_', ' ')}</span>
      </div>
    </div>
    <div class="drawer-footer">
      <button onclick={() => lastRequest = null} class="btn btn-ghost">Close</button>
      <button
        onclick={() => { lastRequest = null; switchView('approvals') }}
        class="btn btn-primary"
      >
        Go to Approvals
      </button>
    </div>
  </div>
{/if}

<!-- ── Posting detail drawer ────────────────────────── -->
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
