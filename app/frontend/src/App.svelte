<script>
  import { onMount } from 'svelte'
  import { auth, ui, VIEW_PATHS } from './lib/store.svelte.js'
  import { switchView, refreshView } from './lib/actions.js'
  import Login from './components/Login.svelte'
  import SetupPassword from './components/SetupPassword.svelte'
  import ForgotPassword from './components/ForgotPassword.svelte'
  import ResetPassword from './components/ResetPassword.svelte'
  import TotpSetup from './components/TotpSetup.svelte'
  import Sidebar from './components/Sidebar.svelte'
  import ToastContainer from './components/ToastContainer.svelte'
  import Dashboard from './components/views/Dashboard.svelte'
  import Accounts from './components/views/Accounts.svelte'
  import AccountDetail from './components/views/AccountDetail.svelte'
  import Customers from './components/views/Customers.svelte'
  import Transactions from './components/views/Transactions.svelte'
  import Users from './components/views/Users.svelte'
  import Roles from './components/views/Roles.svelte'
  import Scopes from './components/views/Scopes.svelte'
  import ApiKeys from './components/views/ApiKeys.svelte'
  import Approvals from './components/views/Approvals.svelte'
  import Payments from './components/views/Payments.svelte'
  import SepaCreditTransfers from './components/views/SepaCreditTransfers.svelte'
  import Events from './components/views/Events.svelte'
  import PermissionErrorDialog from './components/PermissionErrorDialog.svelte'

  const KNOWN_VIEWS = ['dashboard', 'accounts', 'customers', 'postings', 'users', 'roles', 'scopes', 'api_keys', 'approvals', 'payments', 'sepa_credit_transfers', 'events']
  const PRE_AUTH_VIEWS = ['setup-password', 'forgot-password', 'reset-password']

  let preAuthView = $state(null)
  let preAuthParams = $state({})

  function parsePreAuthHash() {
    const raw = window.location.hash.slice(1)
    const [view, qs] = raw.split('?')
    if (!PRE_AUTH_VIEWS.includes(view)) { preAuthView = null; return }
    const params = {}
    if (qs) qs.split('&').forEach(p => { const [k, v] = p.split('='); params[k] = decodeURIComponent(v || '') })
    preAuthView = view
    preAuthParams = params
  }

  onMount(() => {
    parsePreAuthHash()

    if (auth.token) {
      const hash = window.location.hash.slice(1)
      switchView(KNOWN_VIEWS.includes(hash) ? hash : 'dashboard')
    }

    function onHashChange() {
      parsePreAuthHash()
      if (!auth.token) return
      const hash = window.location.hash.slice(1)
      if (hash === 'accounts' && ui.view === 'account_detail') {
        ui.view = 'accounts'
        ui.selectedAccount = null
        return
      }
      if (hash && hash !== ui.view) switchView(hash)
    }
    window.addEventListener('hashchange', onHashChange)

    const timer = setInterval(() => {
      if (auth.token && VIEW_PATHS[ui.view]) refreshView(ui.view)
    }, 5000)

    return () => {
      clearInterval(timer)
      window.removeEventListener('hashchange', onHashChange)
    }
  })
</script>

<ToastContainer />
<PermissionErrorDialog />

{#if !auth.token}
  {#if preAuthView === 'setup-password'}
    <SetupPassword userId={preAuthParams.user_id} token={preAuthParams.token} />
  {:else if preAuthView === 'forgot-password'}
    <ForgotPassword />
  {:else if preAuthView === 'reset-password'}
    <ResetPassword userId={preAuthParams.user_id} token={preAuthParams.token} />
  {:else}
    <Login />
  {/if}
{:else}
  <div class="flex h-screen overflow-hidden">
    <Sidebar currentView={ui.view} />

    <div class="flex-1 flex flex-col overflow-hidden">
      <main class="flex-1 overflow-y-auto p-6">
        {#if ui.view === 'dashboard'}
          <Dashboard />
        {:else if ui.view === 'accounts'}
          <Accounts />
        {:else if ui.view === 'account_detail' && ui.selectedAccount}
          <AccountDetail account={ui.selectedAccount} />
        {:else if ui.view === 'customers'}
          <Customers />
        {:else if ui.view === 'postings'}
          <Transactions />
        {:else if ui.view === 'users'}
          <Users />
        {:else if ui.view === 'roles'}
          <Roles />
        {:else if ui.view === 'scopes'}
          <Scopes />
        {:else if ui.view === 'api_keys'}
          <ApiKeys />
        {:else if ui.view === 'approvals'}
          <Approvals />
        {:else if ui.view === 'payments'}
          <Payments />
        {:else if ui.view === 'sepa_credit_transfers'}
          <SepaCreditTransfers />
        {:else if ui.view === 'events'}
          <Events />
        {:else if ui.view === 'totp_setup'}
          <TotpSetup />
        {/if}
      </main>
    </div>
  </div>
{/if}
