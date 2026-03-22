<script>
  import { onMount } from 'svelte'
  import { ui } from '../../lib/store.svelte.js'
  import { switchView } from '../../lib/actions.js'
  import { apiFetch } from '../../lib/api.js'

  let stats = $state({
    accounts:              { count: null, hasMore: false },
    customers:             { count: null, hasMore: false },
    postings:              { count: null, hasMore: false },
    users:                 { count: null, hasMore: false },
    roles:                 { count: null, hasMore: false },
    scopes:                { count: null, hasMore: false },
    api_keys:              { count: null, hasMore: false },
    approvals:             { count: null, hasMore: false },
    sepa_credit_transfers: { count: null, hasMore: false },
  })

  const PATHS = {
    accounts:              '/accounts/?limit=200',
    customers:             '/customers/?limit=200',
    postings:              '/ledger/transactions/postings/?limit=200',
    users:                 '/users/?limit=200',
    roles:                 '/roles/?limit=200',
    scopes:                '/scopes/?limit=200',
    api_keys:              '/api_keys/?limit=200',
    approvals:             '/approvals/?limit=200&status=pending',
    sepa_credit_transfers: '/payments/sepa/credit-transfers/?limit=200&status=pending',
  }

  onMount(async () => {
    await Promise.allSettled(
      Object.entries(PATHS).map(async ([key, path]) => {
        try {
          const res = await apiFetch('GET', path)
          stats[key] = { count: res.data.length, hasMore: res.meta.has_more }
        } catch {
          stats[key] = { count: null, hasMore: false }
        }
      })
    )
  })

  function fmt(s) {
    if (s.count === null) return '…'
    return s.hasMore ? `${s.count}+` : String(s.count)
  }

  const CARDS = [
    { key: 'accounts',  label: 'Accounts',         view: 'accounts',  icon: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><rect x="2" y="7" width="20" height="14" rx="2"/><path d="M16 7V5a2 2 0 00-2-2h-4a2 2 0 00-2 2v2"/></svg>` },
    { key: 'customers', label: 'Customers',         view: 'customers', icon: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 00-3-3.87M16 3.13a4 4 0 010 7.75"/></svg>` },
    { key: 'postings',  label: 'Transactions',      view: 'postings',  icon: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M12 2v20M2 12h20"/><path d="M17 7l-5-5-5 5M7 17l5 5 5-5"/></svg>` },
    { key: 'users',     label: 'Users',             view: 'users',     icon: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M20 21v-2a4 4 0 00-4-4H8a4 4 0 00-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>` },
    { key: 'roles',     label: 'Roles',             view: 'roles',     icon: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>` },
    { key: 'scopes',    label: 'Scopes',            view: 'scopes',    icon: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><circle cx="12" cy="12" r="10"/><line x1="2" y1="12" x2="22" y2="12"/><path d="M12 2a15.3 15.3 0 010 20M12 2a15.3 15.3 0 000 20"/></svg>` },
    { key: 'api_keys',  label: 'API Keys',          view: 'api_keys',  icon: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M21 2l-2 2m-7.61 7.61a5.5 5.5 0 11-7.778 7.778 5.5 5.5 0 017.777-7.777zm0 0L15.5 7.5m0 0l3 3L22 7l-3-3m-3.5 3.5L19 4"/></svg>` },
    { key: 'approvals',             label: 'Pending Approvals',  view: 'approvals', icon: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>` },
    { key: 'sepa_credit_transfers', label: 'Pending Payments',   view: 'payments',  icon: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><rect x="2" y="5" width="20" height="14" rx="2"/><path d="M2 10h20"/><path d="M7 15h2M11 15h4"/></svg>` },
  ]
</script>

<div class="page-header">
  <div>
    <div class="page-title">Dashboard</div>
    <div class="page-subtitle">System overview</div>
  </div>
</div>

<div class="grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-4">
  {#each CARDS as card (card.key)}
    <button
      onclick={() => switchView(card.view)}
      class="card p-5 text-left hover:shadow-md hover:border-zinc-300 transition-all group"
    >
      <div class="flex items-start justify-between mb-3">
        <div class="w-9 h-9 rounded-lg bg-zinc-100 flex items-center justify-center text-zinc-500 group-hover:bg-zinc-200 transition-colors">
          {@html card.icon}
        </div>
        {#if card.key === 'approvals' && stats.approvals.count > 0}
          <span class="badge badge-amber text-xs">action needed</span>
        {/if}
      </div>
      <div class="text-2xl font-bold text-zinc-800 tabular-nums leading-none mb-1">
        {fmt(stats[card.key])}
      </div>
      <div class="text-xs text-zinc-500">{card.label}</div>
    </button>
  {/each}
</div>
