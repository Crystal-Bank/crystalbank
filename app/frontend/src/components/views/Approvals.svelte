<script>
  import { viewData, pagination, ui, approvalsMeta } from '../../lib/store.svelte.js'
  import { loadView, loadMore, collectApproval } from '../../lib/actions.js'

  let activeTab = $state('pending')
  let completedFetchAttempted = false

  let drawerApproval = $state(null)
  let comment = $state('')

  const currentViewId = $derived(activeTab === 'pending' ? 'approvals' : 'approvals_completed')
  const currentData = $derived(activeTab === 'pending' ? viewData.approvals : viewData.approvals_completed)

  function switchTab(tab) {
    activeTab = tab
    if (tab === 'completed' && (!completedFetchAttempted || approvalsMeta.completedDirty)) {
      completedFetchAttempted = true
      approvalsMeta.completedDirty = false
      loadView('approvals_completed')
    }
  }

  function openDrawer(approval) {
    drawerApproval = approval
    comment = ''
  }

  function closeDrawer() {
    drawerApproval = null
  }

  async function handleCollect() {
    try {
      await collectApproval(drawerApproval.id, comment)
      closeDrawer()
    } catch {}
  }

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

<!-- Tabs -->
<div class="flex gap-1 mb-4 border-b border-zinc-200">
  <button
    onclick={() => switchTab('pending')}
    class="px-4 py-2 text-sm font-medium transition-colors border-b-2 -mb-px"
    class:border-zinc-800={activeTab === 'pending'}
    class:text-zinc-800={activeTab === 'pending'}
    class:border-transparent={activeTab !== 'pending'}
    class:text-zinc-400={activeTab !== 'pending'}
    class:hover:text-zinc-600={activeTab !== 'pending'}
  >
    Pending
    {#if viewData.approvals.length > 0 || pagination.hasMore.approvals}
      <span class="ml-1.5 inline-flex items-center justify-center text-xs font-semibold rounded-full px-1.5 py-0.5 min-w-[1.25rem]"
        class:bg-amber-100={activeTab === 'pending'}
        class:text-amber-700={activeTab === 'pending'}
        class:bg-zinc-100={activeTab !== 'pending'}
        class:text-zinc-500={activeTab !== 'pending'}
      >{viewData.approvals.length}{pagination.hasMore.approvals ? '+' : ''}</span>
    {/if}
  </button>
  <button
    onclick={() => switchTab('completed')}
    class="px-4 py-2 text-sm font-medium transition-colors border-b-2 -mb-px"
    class:border-zinc-800={activeTab === 'completed'}
    class:text-zinc-800={activeTab === 'completed'}
    class:border-transparent={activeTab !== 'completed'}
    class:text-zinc-400={activeTab !== 'completed'}
    class:hover:text-zinc-600={activeTab !== 'completed'}
  >
    Completed
  </button>
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
        {#if activeTab === 'pending'}
          <th></th>
        {/if}
      </tr>
    </thead>
    <tbody>
      {#if currentData.length === 0 && ui.loadingView !== currentViewId}
        <tr>
          <td colspan="7" class="text-center py-10 text-zinc-400 text-sm">
            {activeTab === 'pending' ? 'No pending approvals' : 'No completed approvals'}
          </td>
        </tr>
      {/if}
      {#each currentData as a (a.id)}
        <tr onclick={() => openDrawer(a)} class="cursor-pointer">
          <td><span class="mono text-xs">{a.id}</span></td>
          <td><span class="badge badge-zinc">{a.source_aggregate_type}</span></td>
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
          {#if activeTab === 'pending'}
            <td>
              <span class="badge badge-amber">Pending</span>
            </td>
          {/if}
        </tr>
      {/each}
    </tbody>
  </table>
  {#if ui.loadingView === currentViewId}
    <div class="flex justify-center py-6">
      <div class="animate-spin w-5 h-5 border-2 border-zinc-300 border-t-zinc-700 rounded-full"></div>
    </div>
  {/if}
  {#if pagination.hasMore[currentViewId] && !ui.loading}
    <div class="p-4 border-t border-zinc-100 flex justify-center">
      <button onclick={() => loadMore(currentViewId)} class="btn btn-ghost btn-sm">Load more</button>
    </div>
  {/if}
</div>

<!-- Approval detail drawer -->
{#if drawerApproval}
  <div class="drawer-backdrop" onclick={closeDrawer}></div>
  <div class="drawer-panel">
    <div class="drawer-header">
      <div class="drawer-title">Approval Details</div>
      <button onclick={closeDrawer} class="text-zinc-400 hover:text-zinc-700 transition-colors">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
      </button>
    </div>
    <div class="drawer-body">
      <div class="drawer-field">
        <div class="drawer-field-label">ID</div>
        <div class="font-mono text-xs bg-zinc-50 border border-zinc-200 rounded px-2.5 py-1.5 break-all select-all">{drawerApproval.id}</div>
      </div>
      <div class="drawer-field">
        <div class="drawer-field-label">Status</div>
        <div>
          <span class="badge" class:badge-green={drawerApproval.completed} class:badge-amber={!drawerApproval.completed}>
            {drawerApproval.completed ? 'Completed' : 'Pending'}
          </span>
        </div>
      </div>
      <div class="drawer-field">
        <div class="drawer-field-label">Source</div>
        <div class="flex items-center gap-2">
          <span class="badge badge-zinc">{drawerApproval.source_aggregate_type}</span>
          <span class="font-mono text-xs bg-zinc-50 border border-zinc-200 rounded px-2.5 py-1.5 break-all select-all flex-1">{drawerApproval.source_aggregate_id}</span>
        </div>
      </div>
      {#if drawerApproval.requestor_id}
        <div class="drawer-field">
          <div class="drawer-field-label">Requestor ID</div>
          <div class="font-mono text-xs bg-zinc-50 border border-zinc-200 rounded px-2.5 py-1.5 break-all select-all">{drawerApproval.requestor_id}</div>
        </div>
      {/if}
      <div class="drawer-field">
        <div class="drawer-field-label">Required Approvals</div>
        <div class="flex flex-wrap gap-1">
          {#each drawerApproval.required_approvals as perm (perm)}
            {@const collected = drawerApproval.collected_approvals.some(c => c.permissions.includes(perm))}
            <span class="badge" class:badge-green={collected} class:badge-zinc={!collected} title={perm}>
              {shortPerm(perm)}
            </span>
          {/each}
        </div>
      </div>
      <div class="drawer-field">
        <div class="drawer-field-label">Progress</div>
        <div class="flex items-center gap-2">
          <div class="flex-1 h-2 bg-zinc-200 rounded-full overflow-hidden">
            <div
              class="h-full rounded-full transition-all"
              class:bg-green-500={drawerApproval.completed}
              class:bg-amber-400={!drawerApproval.completed}
              style="width: {drawerApproval.required_approvals.length > 0 ? Math.round(drawerApproval.collected_approvals.length / drawerApproval.required_approvals.length * 100) : 100}%"
            ></div>
          </div>
          <span class="text-xs text-zinc-500 tabular-nums whitespace-nowrap">
            {drawerApproval.collected_approvals.length}/{drawerApproval.required_approvals.length}
          </span>
        </div>
      </div>
      {#if drawerApproval.collected_approvals.length > 0}
        <div class="drawer-field">
          <div class="drawer-field-label">Collected</div>
          <div class="space-y-2">
            {#each drawerApproval.collected_approvals as ca (ca.user_id)}
              <div class="bg-zinc-50 border border-zinc-200 rounded p-2 text-xs">
                <div class="font-mono text-zinc-700 break-all">{ca.user_id}</div>
                {#if ca.comment}
                  <div class="text-zinc-500 italic mt-0.5">"{ca.comment}"</div>
                {/if}
              </div>
            {/each}
          </div>
        </div>
      {/if}

      {#if !drawerApproval.completed}
        <div class="border-t border-zinc-100 pt-5 mt-1">
          <div class="text-sm font-semibold text-zinc-700 mb-3">Collect Approval</div>
          <div class="mb-3">
            <label class="field-label">Comment <span class="text-zinc-400 font-normal">(optional)</span></label>
            <input bind:value={comment} type="text" class="field-input" placeholder="Approved after review...">
          </div>
        </div>
      {/if}
    </div>

    {#if !drawerApproval.completed}
      <div class="drawer-footer">
        <button
          onclick={handleCollect}
          class="btn btn-primary w-full"
          disabled={ui.loading}
        >
          Collect Approval
        </button>
      </div>
    {/if}
  </div>
{/if}
