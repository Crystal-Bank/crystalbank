<script>
  import { auth, ui } from './lib/store.svelte.js'
  import { loadView } from './lib/actions.js'
  import Login from './components/Login.svelte'
  import Sidebar from './components/Sidebar.svelte'
  import ScopeBar from './components/ScopeBar.svelte'
  import ToastContainer from './components/ToastContainer.svelte'
  import Accounts from './components/views/Accounts.svelte'
  import Customers from './components/views/Customers.svelte'
  import Transactions from './components/views/Transactions.svelte'
  import Users from './components/views/Users.svelte'
  import Roles from './components/views/Roles.svelte'
  import Scopes from './components/views/Scopes.svelte'
  import ApiKeys from './components/views/ApiKeys.svelte'

  $effect(() => {
    if (auth.token) loadView('accounts')
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
        {#if ui.view === 'accounts'}
          <Accounts />
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
        {/if}
      </main>
    </div>
  </div>
{/if}
