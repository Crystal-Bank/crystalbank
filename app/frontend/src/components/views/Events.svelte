<script>
  import { onMount } from 'svelte'
  import { apiFetch } from '../../lib/api.js'
  import { formatDate } from '../../lib/utils.js'

  // Local state — not in global store because results depend on filters
  let events = $state([])
  let loading = $state(false)
  let hasMore = $state(false)
  let cursor = $state(null)

  // Filter state
  let filterAggregateId = $state('')
  let filterEventId = $state('')
  let filterEventHandle = $state('')

  // Active (applied) filters
  let activeAggregateId = $state('')
  let activeEventId = $state('')
  let activeEventHandle = $state('')

  // Detail drawer
  let drawerEvent = $state(null)
  let copied = $state(null) // 'header' | 'body' | null

  function copyJson(key, value) {
    navigator.clipboard.writeText(JSON.stringify(value, null, 2))
    copied = key
    setTimeout(() => { copied = null }, 1500)
  }

  function buildUrl({ cursorVal = null } = {}) {
    const params = new URLSearchParams()
    params.set('limit', '20')
    if (activeAggregateId) params.set('aggregate_id', activeAggregateId)
    if (activeEventId) params.set('event_id', activeEventId)
    if (activeEventHandle) params.set('event_handle', activeEventHandle)
    if (cursorVal) params.set('cursor', cursorVal)
    return '/events/?' + params.toString()
  }

  async function load(opts = {}) {
    if (loading) return
    loading = true
    try {
      const url = buildUrl(opts)
      const res = await apiFetch('GET', url)
      const items = (res.data ?? []).map(e => ({
        id: e.attributes.id,
        scope_id: e.attributes.scope_id,
        header: e.attributes.header,
        body: e.attributes.body ?? null,
      }))

      if (opts.append) {
        events = [...events, ...items]
      } else {
        events = items
      }

      hasMore = res.meta?.has_more ?? false
      cursor = res.meta?.next_cursor ?? null
    } catch (err) {
      console.error(err)
    } finally {
      loading = false
    }
  }

  function applyFilters() {
    activeAggregateId = filterAggregateId.trim()
    activeEventId = filterEventId.trim()
    activeEventHandle = filterEventHandle.trim()
    cursor = null
    load()
  }

  function clearFilters() {
    filterAggregateId = ''
    filterEventId = ''
    filterEventHandle = ''
    activeAggregateId = ''
    activeEventId = ''
    activeEventHandle = ''
    cursor = null
    load()
  }

  async function loadMore() {
    await load({ cursorVal: cursor, append: true })
  }

  onMount(() => load())
</script>

<div class="page-header">
  <div>
    <div class="page-title">Events</div>
    <div class="page-subtitle">Audit log of all domain events</div>
  </div>
</div>

<!-- Filter bar -->
<div class="card mb-4 p-4">
  <div class="flex flex-wrap gap-3 items-end">
    <div class="flex-1 min-w-40">
      <label class="field-label">Aggregate ID</label>
      <input
        bind:value={filterAggregateId}
        type="text"
        class="field-input font-mono text-xs"
        placeholder="UUID"
        onkeydown={(e) => e.key === 'Enter' && applyFilters()}
      >
    </div>
    <div class="flex-1 min-w-40">
      <label class="field-label">Event ID</label>
      <input
        bind:value={filterEventId}
        type="text"
        class="field-input font-mono text-xs"
        placeholder="UUID"
        onkeydown={(e) => e.key === 'Enter' && applyFilters()}
      >
    </div>
    <div class="flex-1 min-w-40">
      <label class="field-label">Event Handle</label>
      <input
        bind:value={filterEventHandle}
        type="text"
        class="field-input text-xs"
        placeholder="e.g. user.onboarding.requested"
        onkeydown={(e) => e.key === 'Enter' && applyFilters()}
      >
    </div>
    <div class="flex gap-2 shrink-0">
      <button onclick={applyFilters} class="btn btn-primary btn-sm" disabled={loading}>Apply</button>
      <button onclick={clearFilters} class="btn btn-ghost btn-sm" disabled={loading}>Clear</button>
    </div>
  </div>
</div>

<div class="card overflow-hidden">
  <table class="data-table">
    <thead>
      <tr>
        <th>Event ID</th>
        <th>Event Handle</th>
        <th>Aggregate ID</th>
        <th>Version</th>
      </tr>
    </thead>
    <tbody>
      {#if events.length === 0 && !loading}
        <tr><td colspan="4" class="text-center py-10 text-zinc-400 text-sm">No events found</td></tr>
      {/if}
      {#each events as ev (ev.id)}
        <tr onclick={() => drawerEvent = ev} class="cursor-pointer">
          <td><span class="mono text-xs">{ev.id}</span></td>
          <td><span class="font-mono text-xs">{ev.header?.event_handle ?? '—'}</span></td>
          <td><span class="mono text-xs">{ev.header?.aggregate_id ?? '—'}</span></td>
          <td class="text-zinc-500 text-xs tabular-nums">{ev.header?.aggregate_version ?? '—'}</td>
        </tr>
      {/each}
    </tbody>
  </table>

  {#if loading}
    <div class="flex justify-center py-6">
      <div class="animate-spin w-5 h-5 border-2 border-zinc-300 border-t-zinc-700 rounded-full"></div>
    </div>
  {/if}

  {#if hasMore && !loading}
    <div class="p-4 border-t border-zinc-100 flex justify-center">
      <button onclick={loadMore} class="btn btn-ghost btn-sm">Load more</button>
    </div>
  {/if}
</div>

<!-- Event detail drawer -->
{#if drawerEvent}
  <div class="drawer-backdrop" onclick={() => drawerEvent = null}></div>
  <div class="drawer-panel">
    <div class="drawer-header">
      <div class="drawer-title">Event Details</div>
      <button onclick={() => drawerEvent = null} class="text-zinc-400 hover:text-zinc-700 transition-colors">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
      </button>
    </div>
    <div class="drawer-body">
      <div class="drawer-field">
        <div class="drawer-field-label">Event ID</div>
        <div class="font-mono text-xs bg-zinc-50 border border-zinc-200 rounded px-2.5 py-1.5 break-all select-all">{drawerEvent.id}</div>
      </div>
      <div class="drawer-field">
        <div class="drawer-field-label">Aggregate ID</div>
        <div class="font-mono text-xs bg-zinc-50 border border-zinc-200 rounded px-2.5 py-1.5 break-all select-all">{drawerEvent.header?.aggregate_id ?? '—'}</div>
      </div>
      <div class="drawer-field">
        <div class="drawer-field-label">Scope ID</div>
        <div class="font-mono text-xs bg-zinc-50 border border-zinc-200 rounded px-2.5 py-1.5 break-all select-all">{drawerEvent.scope_id}</div>
      </div>
      <div class="drawer-field">
        <div class="flex items-center justify-between mb-1">
          <div class="drawer-field-label">Header</div>
          <button onclick={() => copyJson('header', drawerEvent.header)} class="text-xs text-zinc-400 hover:text-zinc-700 transition-colors tabular-nums w-12 text-right">
            {copied === 'header' ? 'Copied!' : 'Copy'}
          </button>
        </div>
        <pre class="text-xs bg-zinc-50 border border-zinc-200 rounded px-2.5 py-1.5 overflow-x-auto whitespace-pre-wrap break-words">{JSON.stringify(drawerEvent.header, null, 2)}</pre>
      </div>
      {#if drawerEvent.body !== null}
        <div class="drawer-field">
          <div class="flex items-center justify-between mb-1">
            <div class="drawer-field-label">Body</div>
            <button onclick={() => copyJson('body', drawerEvent.body)} class="text-xs text-zinc-400 hover:text-zinc-700 transition-colors tabular-nums w-12 text-right">
              {copied === 'body' ? 'Copied!' : 'Copy'}
            </button>
          </div>
          <pre class="text-xs bg-zinc-50 border border-zinc-200 rounded px-2.5 py-1.5 overflow-x-auto whitespace-pre-wrap break-words">{JSON.stringify(drawerEvent.body, null, 2)}</pre>
        </div>
      {/if}
    </div>
  </div>
{/if}
