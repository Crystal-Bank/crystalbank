<script>
  import { switchView } from '../../lib/actions.js'

  const PAYMENT_TYPES = [
    {
      id: 'sepa_credit_transfers',
      scheme: 'SEPA',
      label: 'SEPA Credit Transfer',
      description: 'Send a euro payment within the SEPA zone. The transfer enters an approval workflow before ledger postings are created.',
      available: true,
      icon: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><rect x="2" y="5" width="20" height="14" rx="2"/><path d="M2 10h20"/><path d="M7 15h2M11 15h4"/></svg>`,
    },
    {
      id: null,
      scheme: 'SEPA',
      label: 'SEPA Direct Debit',
      description: 'Pull funds from a debtor account using a SEPA mandate.',
      available: false,
      icon: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><rect x="2" y="5" width="20" height="14" rx="2"/><path d="M2 10h20"/><path d="M17 15h-2M13 15H9"/></svg>`,
    },
    {
      id: null,
      scheme: 'T2',
      label: 'T2 Credit Transfer',
      description: 'High-value euro payment settled via the Eurosystem TARGET2 platform.',
      available: false,
      icon: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><circle cx="12" cy="12" r="10"/><path d="M8 12h8M14 8l4 4-4 4"/></svg>`,
    },
    {
      id: null,
      scheme: 'Faster Payments',
      label: 'Faster Payments',
      description: 'Near-instant GBP payments within the UK Faster Payments scheme.',
      available: false,
      icon: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M13 2L3 14h9l-1 8 10-12h-9l1-8z"/></svg>`,
    },
  ]
</script>

<div class="page-header">
  <div>
    <div class="page-title">Payments</div>
    <div class="page-subtitle">Choose a payment type to initiate or view</div>
  </div>
</div>

<div class="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-2">
  {#each PAYMENT_TYPES as pt (pt.label)}
    <div
      class="card p-5 flex flex-col gap-3 {pt.available ? 'hover:shadow-md hover:border-zinc-300 transition-all cursor-pointer group' : 'opacity-50'}"
      role={pt.available ? 'button' : undefined}
      tabindex={pt.available ? 0 : undefined}
      onclick={pt.available ? () => switchView(pt.id) : undefined}
      onkeydown={pt.available ? (e) => { if (e.key === 'Enter' || e.key === ' ') switchView(pt.id) } : undefined}
    >
      <div class="flex items-start justify-between">
        <div class="w-10 h-10 rounded-lg bg-zinc-100 flex items-center justify-center text-zinc-500 {pt.available ? 'group-hover:bg-zinc-200 transition-colors' : ''}">
          {@html pt.icon}
        </div>
        <div class="flex items-center gap-2">
          <span class="text-xs font-medium px-2 py-0.5 rounded-full bg-zinc-100 text-zinc-500">{pt.scheme}</span>
          {#if !pt.available}
            <span class="badge badge-zinc text-xs">Coming soon</span>
          {/if}
        </div>
      </div>

      <div>
        <div class="font-semibold text-zinc-800 mb-1">{pt.label}</div>
        <div class="text-xs text-zinc-500 leading-relaxed">{pt.description}</div>
      </div>

      {#if pt.available}
        <div class="mt-auto pt-1">
          <span class="text-xs font-medium text-zinc-600 group-hover:text-zinc-900 transition-colors flex items-center gap-1">
            View transfers
            <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M5 12h14M12 5l7 7-7 7"/></svg>
          </span>
        </div>
      {/if}
    </div>
  {/each}
</div>
