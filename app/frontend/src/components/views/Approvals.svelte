<script>
  import { viewData, pagination, ui } from '../../lib/store.svelte.js'
  import { loadMore, collectApproval } from '../../lib/actions.js'

  let showModal = $state(false)
  let selected = $state(null)
  let comment = $state('')

  function openCollect(approval) {
    selected = approval
    comment = ''
    showModal = true
  }

  async function handleCollect() {
    try {
      await collectApproval(selected.id, comment)
      showModal = false
    } catch {}
  }

  // Abbreviate long permission names for display: strip leading verb and join words
  function shortPerm(p) {
    return p.replace(/^(read|write)_/, '').replaceAll('_', ' ')
  }
</script>

<div class="page-header">
  <div>
    <div class="page-title">Approvals</div>
    <div class="page-subtitle">Pending and completed approval processes</div>
  </div>
</div>

<div class="card overflow-hidden">
  <table class="data-table">
    <thead>
      <tr>
        <th>ID</th>
        <th>Source</th>
        <th>Source ID</th>
        <th>Requestor ID</th>
        <th>Required</th>
        <th>Progress</th>
        <th>Status</th>
        <th></th>
      </tr>
    </thead>
    <tbody>
      {#if viewData.approvals.length === 0 && !ui.loadingView}
        <tr><td colspan="8" class="text-center py-10 text-zinc-400 text-sm">No approvals found</td></tr>
      {/if}
      {#each viewData.approvals as a (a.id)}
        <tr>
          <td><span class="mono text-xs">{a.id}</span></td>
          <td>
            <span class="badge badge-zinc">{a.source_aggregate_type}</span>
          </td>
          <td><span class="mono text-xs">{a.source_aggregate_id}</span></td>
          <td>
            {#if a.requestor_id}
              <span class="mono text-xs">{a.requestor_id}</span>
            {:else}
              <span class="text-zinc-400 text-xs">—</span>
            {/if}
          </td>
          <td>
            <div class="flex flex-wrap gap-1">
              {#each a.required_approvals as perm (perm)}
                <span class="badge badge-zinc" title={perm}>{shortPerm(perm)}</span>
              {/each}
            </div>
          </td>
          <td>
            <div class="flex items-center gap-2">
              <div class="w-20 h-1.5 bg-zinc-200 rounded-full overflow-hidden">
                <div
                  class="h-full rounded-full transition-all"
                  class:bg-green-500={a.completed}
                  class:bg-amber-400={!a.completed}
                  style="width: {a.required_approvals.length > 0 ? Math.round(a.collected_approvals.length / a.required_approvals.length * 100) : 100}%"
                ></div>
              </div>
              <span class="text-xs text-zinc-500 tabular-nums">
                {a.collected_approvals.length}/{a.required_approvals.length}
              </span>
            </div>
          </td>
          <td>
            <span class="badge" class:badge-green={a.completed} class:badge-amber={!a.completed}>
              {a.completed ? 'Completed' : 'Pending'}
            </span>
          </td>
          <td>
            {#if !a.completed}
              <button onclick={() => openCollect(a)} class="btn btn-primary btn-sm">Collect</button>
            {/if}
          </td>
        </tr>
      {/each}
    </tbody>
  </table>
  {#if ui.loadingView === 'approvals'}
    <div class="flex justify-center py-6">
      <div class="animate-spin w-5 h-5 border-2 border-zinc-300 border-t-zinc-700 rounded-full"></div>
    </div>
  {/if}
  {#if pagination.hasMore.approvals && !ui.loading}
    <div class="p-4 border-t border-zinc-100 flex justify-center">
      <button onclick={() => loadMore('approvals')} class="btn btn-ghost btn-sm">Load more</button>
    </div>
  {/if}
</div>

{#if showModal && selected}
  <div class="modal-backdrop" onclick={(e) => { if (e.target === e.currentTarget) showModal = false }}>
    <div class="modal-box">
      <div class="modal-title">Collect Approval</div>
      <div class="modal-desc">Submit your approval for this process. Requires the matching permission in your role.</div>

      <div class="mb-4 p-3 bg-zinc-50 border border-zinc-200 rounded-lg space-y-2 text-xs">
        <div>
          <span class="text-zinc-400 uppercase tracking-wide font-medium">Approval ID</span>
          <div class="mono mt-0.5">{selected.id}</div>
        </div>
        <div>
          <span class="text-zinc-400 uppercase tracking-wide font-medium">Source</span>
          <div class="mt-0.5">
            <span class="badge badge-zinc mr-1">{selected.source_aggregate_type}</span>
            <span class="mono">{selected.source_aggregate_id}</span>
          </div>
        </div>
        <div>
          <span class="text-zinc-400 uppercase tracking-wide font-medium">Required</span>
          <div class="flex flex-wrap gap-1 mt-0.5">
            {#each selected.required_approvals as perm (perm)}
              {@const collected = selected.collected_approvals.some(c => c.permissions.includes(perm))}
              <span class="badge" class:badge-green={collected} class:badge-zinc={!collected} title={perm}>
                {shortPerm(perm)}
              </span>
            {/each}
          </div>
        </div>
        {#if selected.collected_approvals.length > 0}
          <div>
            <span class="text-zinc-400 uppercase tracking-wide font-medium">Collected</span>
            <div class="space-y-1 mt-0.5">
              {#each selected.collected_approvals as ca (ca.user_id)}
                <div class="flex items-start gap-2">
                  <span class="mono">{ca.user_id}</span>
                  {#if ca.comment}
                    <span class="text-zinc-500 italic">"{ca.comment}"</span>
                  {/if}
                </div>
              {/each}
            </div>
          </div>
        {/if}
      </div>

      <form onsubmit={(e) => { e.preventDefault(); handleCollect() }}>
        <div class="mb-5">
          <label class="field-label">Comment</label>
          <input bind:value={comment} type="text" class="field-input" placeholder="Approved after review..." required>
          <div class="field-hint">A note explaining your approval decision</div>
        </div>
        <div class="flex gap-2 justify-end">
          <button type="button" onclick={() => showModal = false} class="btn btn-ghost">Cancel</button>
          <button type="submit" class="btn btn-primary" disabled={ui.loading}>Collect Approval</button>
        </div>
      </form>
    </div>
  </div>
{/if}
