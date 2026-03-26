<script>
  import { onMount } from 'svelte'
  import { auth, ui, VIEW_PATHS } from './lib/store.svelte.js'
  import { switchView, refreshView } from './lib/actions.js'
  import Login from './components/Login.svelte'
  import Sidebar from './components/Sidebar.svelte'
  import ScopeBar from './components/ScopeBar.svelte'
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

  const KNOWN_VIEWS = ['dashboard', 'accounts', 'customers', 'postings', 'users', 'roles', 'scopes', 'api_keys', 'approvals', 'payments', 'sepa_credit_transfers']

  onMount(() => {
    if (auth.token) {
      const hash = window.location.hash.slice(1)
      switchView(KNOWN_VIEWS.includes(hash) ? hash : 'dashboard')
    }

    function onHashChange() {
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

{#if !auth.token}
  <Login />
{:else}
  <div class="flex h-screen overflow-hidden">
    <Sidebar currentView={ui.view} />

    <div class="flex-1 flex flex-col overflow-hidden">
      <ScopeBar />

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
        {/if}
      </main>
    </div>
  </div>
{/if}
