<script>
  import { viewData, pagination, ui } from '../../lib/store.svelte.js'
  import { loadMore, createSepaCreditTransfer } from '../../lib/actions.js'
  import { apiFetch } from '../../lib/api.js'

  // ── Create modal ──────────────────────────────────────────────────────────────
  let showModal = $state(false)
  let accountOptions = $state([])

  let form = $state({
    debtor_account_id: '',
    creditor_name: '',
    creditor_iban: '',
    creditor_bic: '',
    amount: '',
    remittance_information: '',
    end_to_end_id: '',
  })

  let ibanError = $state('')

  // Expected IBAN lengths per country (ISO 13616 / SWIFT registry)
  const IBAN_LENGTHS = {
    AD:28,AE:23,AL:28,AT:20,AZ:28,BA:20,BE:16,BG:22,BH:22,BR:29,BY:28,CH:21,
    CR:22,CY:28,CZ:24,DE:22,DK:18,DO:28,EE:20,EG:29,ES:24,FI:18,FO:18,FR:27,
    GB:22,GE:22,GI:23,GL:18,GT:28,HR:21,HU:28,IE:22,IL:23,IQ:23,IS:26,IT:27,
    JO:30,KW:30,KZ:20,LB:28,LC:32,LI:21,LT:20,LU:20,LV:21,MC:27,MD:24,ME:22,
    MK:19,MR:27,MT:31,MU:30,NI:28,NL:18,NO:15,PK:24,PL:28,PS:29,PT:25,QA:29,
    RO:24,RS:22,SA:24,SC:31,SE:24,SI:19,SK:24,SM:27,ST:25,SV:28,TL:23,TN:24,
    TR:26,UA:29,VA:22,VG:24,XK:20,
  }

  function validateIban(value) {
    const iban = value.replace(/\s+/g, '').toUpperCase()
    if (!iban) return ''
    if (!/^[A-Z]{2}[0-9]{2}[A-Z0-9]{1,30}$/.test(iban)) return 'Invalid IBAN format'
    const country = iban.slice(0, 2)
    const expectedLength = IBAN_LENGTHS[country]
    if (!expectedLength) return `Unsupported country code: ${country}`
    if (iban.length !== expectedLength) return `Invalid length for ${country} IBAN (expected ${expectedLength} characters)`
    const rearranged = iban.slice(4) + iban.slice(0, 4)
    const numeric = rearranged.split('').map(c => c >= 'A' ? String(c.charCodeAt(0) - 55) : c).join('')
    let remainder = 0
    for (let i = 0; i < numeric.length; i++) {
      remainder = (remainder * 10 + parseInt(numeric[i], 10)) % 97
    }
    return remainder === 1 ? '' : 'IBAN checksum is invalid'
  }

  function onIbanInput() {
    ibanError = validateIban(form.creditor_iban)
  }

  let debtorQuery = $state('')
  let debtorOpen  = $state(false)

  const INTERNAL_ACCOUNT_TYPES = ['settlement', 'nostro', 'cpd', 'frozen_funds']

  let debtorSuggestions = $derived(
    accountOptions
      .filter(a => {
        const q = debtorQuery.toLowerCase()
        return (q === '' || a.id.toLowerCase().includes(q) || (a.name ?? '').toLowerCase().includes(q)) &&
               (a.currencies ?? []).map(c => c.toLowerCase()).includes('eur') &&
               !INTERNAL_ACCOUNT_TYPES.includes(a.type?.toLowerCase())
      })
      .slice(0, 8)
  )

  async function openModal() {
    form = {
      debtor_account_id: '',
      creditor_name: '',
      creditor_iban: '',
      creditor_bic: '',
      amount: '',
      remittance_information: '',
      end_to_end_id: '',
    }
    ibanError = ''
    debtorQuery = ''
    debtorOpen = false
    showModal = true
    try {
      const res = await apiFetch('GET', '/accounts/?limit=200')
      accountOptions = res.data.map(e => e.attributes)
    } catch {
      accountOptions = []
    }
  }

  function selectDebtor(accountId) {
    form.debtor_account_id = accountId
    debtorQuery = accountId
    debtorOpen = false
  }

  async function handleSubmit() {
    ibanError = validateIban(form.creditor_iban)
    if (ibanError) return
    try {
      await createSepaCreditTransfer({
        debtor_account_id:      form.debtor_account_id,
        creditor_name:          form.creditor_name.trim(),
        creditor_iban:          form.creditor_iban.trim(),
        creditor_bic:           form.creditor_bic.trim() || undefined,
        amount:                 parseInt(form.amount, 10),
        currency:               'EUR',
        remittance_information: form.remittance_information.trim(),
        end_to_end_id:          form.end_to_end_id.trim() || undefined,
      })
      showModal = false
    } catch {}
  }

  // ── Detail drawer ─────────────────────────────────────────────────────────────
  let drawerTransfer = $state(null)

  function statusBadgeClass(status) {
    if (status === 'accepted') return 'badge-green'
    return 'badge-amber'
  }

  function fmtAmount(cents) {
    return (cents / 100).toLocaleString('en-GB', { minimumFractionDigits: 2, maximumFractionDigits: 2 })
  }

  function fmtDate(iso) {
    if (!iso) return '—'
    return iso.split('T')[0]
  }
</script>

<div class="page-header">
  <div>
    <div class="page-title">SEPA Credit Transfers</div>
    <div class="page-subtitle">Outgoing SEPA payments pending and accepted</div>
  </div>
  <button onclick={openModal} class="btn btn-primary btn-sm">
    <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
      <line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/>
    </svg>
    New Transfer
  </button>
</div>

<!-- Transfers table -->
<div class="card overflow-hidden">
  <table class="data-table">
    <thead>
      <tr>
        <th>End-to-End ID</th>
        <th>Creditor</th>
        <th>IBAN</th>
        <th>Amount (EUR)</th>
        <th>Execution Date</th>
        <th>Status</th>
      </tr>
    </thead>
    <tbody>
      {#if viewData.sepa_credit_transfers.length === 0 && ui.loadingView !== 'sepa_credit_transfers'}
        <tr>
          <td colspan="6" class="text-center py-10 text-zinc-400 text-sm">No SEPA Credit Transfers found</td>
        </tr>
      {/if}
      {#each viewData.sepa_credit_transfers as t (t.id)}
        <tr onclick={() => drawerTransfer = t} class="cursor-pointer">
          <td><span class="mono text-xs">{t.end_to_end_id}</span></td>
          <td class="font-medium">{t.creditor_name}</td>
          <td><span class="mono text-xs">{t.creditor_iban}</span></td>
          <td class="tabular-nums font-semibold">{fmtAmount(t.amount)}</td>
          <td class="text-zinc-500 text-xs tabular-nums">{fmtDate(t.execution_date)}</td>
          <td><span class="badge {statusBadgeClass(t.status)}">{t.status}</span></td>
        </tr>
      {/each}
    </tbody>
  </table>

  {#if ui.loadingView === 'sepa_credit_transfers'}
    <div class="flex justify-center py-6">
      <div class="animate-spin w-5 h-5 border-2 border-zinc-300 border-t-zinc-700 rounded-full"></div>
    </div>
  {/if}
  {#if pagination.hasMore.sepa_credit_transfers && !ui.loading}
    <div class="p-4 border-t border-zinc-100 flex justify-center">
      <button onclick={() => loadMore('sepa_credit_transfers')} class="btn btn-ghost btn-sm">Load more</button>
    </div>
  {/if}
</div>

<!-- ── Create modal ──────────────────────────────────────────────────────────── -->
{#if showModal}
  <!-- svelte-ignore a11y_click_events_have_key_events a11y_no_static_element_interactions -->
  <div class="modal-backdrop" onclick={() => showModal = false}></div>
  <div class="modal-box modal-box-lg" style="position:fixed;top:50%;left:50%;transform:translate(-50%,-50%);z-index:51;overflow-y:auto;">
    <div class="flex items-center justify-between mb-5">
      <h2 class="text-base font-semibold">New SEPA Credit Transfer</h2>
      <button onclick={() => showModal = false} class="text-zinc-400 hover:text-zinc-700">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>
        </svg>
      </button>
    </div>

    <form onsubmit={(e) => { e.preventDefault(); handleSubmit() }} class="space-y-3">

      <!-- ── 1. Debtor ── -->
      <div class="bg-zinc-50 border border-zinc-200 rounded-lg p-4">
        <p class="text-xs font-semibold text-zinc-400 uppercase tracking-wide mb-3">Debtor</p>
        <div class="relative">
          <label class="field-label" for="debtor">Account <span class="text-zinc-400 font-normal">EUR · active</span></label>
          <input
            id="debtor"
            class="field-input"
            required
            autocomplete="off"
            bind:value={debtorQuery}
            oninput={() => { form.debtor_account_id = debtorQuery; debtorOpen = true }}
            onfocus={() => debtorOpen = true}
            placeholder="Paste or search account ID"
          />
          {#if debtorOpen && debtorSuggestions.length > 0}
            <div class="absolute z-10 w-full mt-1 bg-white border border-zinc-200 rounded-md shadow-lg max-h-48 overflow-y-auto">
              {#each debtorSuggestions as a (a.id)}
                <!-- svelte-ignore a11y_click_events_have_key_events a11y_no_static_element_interactions -->
                <div onclick={() => selectDebtor(a.id)} class="px-3 py-2 text-sm cursor-pointer hover:bg-zinc-50">
                  <div class="font-medium text-xs text-zinc-800">{a.name}</div>
                  <div class="flex items-center gap-2 mt-0.5">
                    <span class="font-mono text-xs text-zinc-400 flex-1 truncate">{a.id}</span>
                    <span class="text-zinc-400 text-xs shrink-0">{a.type}</span>
                  </div>
                </div>
              {/each}
            </div>
          {/if}
        </div>
      </div>

      <!-- ── 2. Creditor information ── -->
      <div class="bg-zinc-50 border border-zinc-200 rounded-lg p-4">
        <p class="text-xs font-semibold text-zinc-400 uppercase tracking-wide mb-3">Creditor information</p>
        <div class="space-y-4">
          <div>
            <label class="field-label" for="creditor-name">Creditor Name</label>
            <input id="creditor-name" class="field-input" required bind:value={form.creditor_name} placeholder="Acme GmbH"/>
          </div>
          <div>
            <label class="field-label" for="creditor-iban">Creditor IBAN</label>
            <input
              id="creditor-iban"
              class="field-input font-mono {ibanError ? 'border-red-400 focus:ring-red-300' : ''}"
              required
              bind:value={form.creditor_iban}
              oninput={onIbanInput}
              placeholder="DE89370400440532013000"
            />
            {#if ibanError}
              <p class="mt-1 text-xs text-red-500">{ibanError}</p>
            {/if}
          </div>
          <div>
            <label class="field-label" for="creditor-bic">Creditor BIC <span class="text-zinc-400 font-normal">(optional)</span></label>
            <input id="creditor-bic" class="field-input font-mono" bind:value={form.creditor_bic} placeholder="COBADEFFXXX"/>
          </div>
        </div>
      </div>

      <!-- ── 3. Amount ── -->
      <div class="bg-zinc-50 border border-zinc-200 rounded-lg p-4">
        <p class="text-xs font-semibold text-zinc-400 uppercase tracking-wide mb-3">Amount</p>
        <label class="field-label" for="amount">Amount <span class="text-zinc-400 font-normal">(EUR cents)</span></label>
        <input id="amount" class="field-input" type="number" min="1" required bind:value={form.amount} placeholder="10000"/>
      </div>

      <!-- ── 4. Remittance information ── -->
      <div class="bg-zinc-50 border border-zinc-200 rounded-lg p-4">
        <p class="text-xs font-semibold text-zinc-400 uppercase tracking-wide mb-3">Remittance information</p>
        <label class="field-label" for="remittance">Remittance Information <span class="text-zinc-400 font-normal">(max 140 chars)</span></label>
        <input id="remittance" class="field-input" maxlength="140" required bind:value={form.remittance_information} placeholder="Invoice #42"/>
      </div>

      <!-- ── 5. End-to-End ID (optional) ── -->
      <div class="bg-zinc-50 border border-zinc-200 rounded-lg p-4">
        <p class="text-xs font-semibold text-zinc-400 uppercase tracking-wide mb-3">End-to-End ID <span class="normal-case font-normal">(optional)</span></p>
        <label class="field-label" for="e2e">End-to-End ID <span class="text-zinc-400 font-normal">(max 35 chars)</span></label>
        <input id="e2e" class="field-input" maxlength="35" bind:value={form.end_to_end_id} placeholder="E2E-2026-001"/>
      </div>

      <p class="px-1 text-xs text-zinc-400">
        Currency is always <strong class="text-zinc-600">EUR</strong>. After submission, an approval workflow is created — the transfer posts to the ledger once approved.
      </p>

      <div class="flex justify-end gap-2 pt-2">
        <button type="button" onclick={() => showModal = false} class="btn btn-ghost btn-sm">Cancel</button>
        <button type="submit" class="btn btn-primary btn-sm" disabled={ui.loading}>
          {ui.loading ? 'Submitting…' : 'Submit Transfer'}
        </button>
      </div>
    </form>
  </div>
{/if}

<!-- ── Detail drawer ──────────────────────────────────────────────────────────── -->
{#if drawerTransfer}
  <!-- svelte-ignore a11y_click_events_have_key_events a11y_no_static_element_interactions -->
  <div class="drawer-backdrop" onclick={() => drawerTransfer = null}></div>
  <div class="drawer-panel overflow-y-auto" style="z-index:41;box-shadow:-4px 0 24px rgba(0,0,0,0.08);padding:1.5rem;">
    <div class="flex items-center justify-between mb-5">
      <h2 class="text-base font-semibold">SEPA Credit Transfer</h2>
      <button onclick={() => drawerTransfer = null} class="text-zinc-400 hover:text-zinc-700">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>
        </svg>
      </button>
    </div>

    <!-- Status -->
    <div class="mb-5">
      <span class="badge {statusBadgeClass(drawerTransfer.status)} text-sm px-3 py-1">{drawerTransfer.status}</span>
    </div>

    <dl class="space-y-3 text-sm">
      <div>
        <dt class="text-xs font-medium text-zinc-400 uppercase tracking-wide mb-0.5">Payment ID</dt>
        <dd class="mono text-xs break-all">{drawerTransfer.id}</dd>
      </div>
      <div>
        <dt class="text-xs font-medium text-zinc-400 uppercase tracking-wide mb-0.5">End-to-End ID</dt>
        <dd class="mono text-xs">{drawerTransfer.end_to_end_id}</dd>
      </div>

      <div class="border-t border-zinc-100 pt-3">
        <dt class="text-xs font-medium text-zinc-400 uppercase tracking-wide mb-1">Debtor Account</dt>
        <dd class="mono text-xs break-all">{drawerTransfer.debtor_account_id}</dd>
      </div>

      <div class="border-t border-zinc-100 pt-3">
        <dt class="text-xs font-medium text-zinc-400 uppercase tracking-wide mb-0.5">Creditor Name</dt>
        <dd class="font-medium">{drawerTransfer.creditor_name}</dd>
      </div>
      <div>
        <dt class="text-xs font-medium text-zinc-400 uppercase tracking-wide mb-0.5">Creditor IBAN</dt>
        <dd class="mono text-xs">{drawerTransfer.creditor_iban}</dd>
      </div>
      {#if drawerTransfer.creditor_bic}
        <div>
          <dt class="text-xs font-medium text-zinc-400 uppercase tracking-wide mb-0.5">Creditor BIC</dt>
          <dd class="mono text-xs">{drawerTransfer.creditor_bic}</dd>
        </div>
      {/if}

      <div class="border-t border-zinc-100 pt-3">
        <dt class="text-xs font-medium text-zinc-400 uppercase tracking-wide mb-0.5">Amount</dt>
        <dd class="text-xl font-bold tabular-nums">€{fmtAmount(drawerTransfer.amount)}</dd>
      </div>
      <div>
        <dt class="text-xs font-medium text-zinc-400 uppercase tracking-wide mb-0.5">Execution Date</dt>
        <dd>{fmtDate(drawerTransfer.execution_date)}</dd>
      </div>
      <div>
        <dt class="text-xs font-medium text-zinc-400 uppercase tracking-wide mb-0.5">Remittance Information</dt>
        <dd class="text-zinc-600">{drawerTransfer.remittance_information}</dd>
      </div>

      {#if drawerTransfer.ledger_transaction_id}
        <div class="border-t border-zinc-100 pt-3">
          <dt class="text-xs font-medium text-zinc-400 uppercase tracking-wide mb-0.5">Ledger Transaction</dt>
          <dd class="mono text-xs break-all">{drawerTransfer.ledger_transaction_id}</dd>
        </div>
      {/if}

      <div class="border-t border-zinc-100 pt-3">
        <dt class="text-xs font-medium text-zinc-400 uppercase tracking-wide mb-0.5">Scope</dt>
        <dd class="mono text-xs break-all">{drawerTransfer.scope_id}</dd>
      </div>
      <div>
        <dt class="text-xs font-medium text-zinc-400 uppercase tracking-wide mb-0.5">Created</dt>
        <dd class="text-zinc-500 text-xs">{drawerTransfer.created_at?.replace('T', ' ').replace('Z', ' UTC')}</dd>
      </div>
    </dl>
  </div>
{/if}
