<script>
  import { login } from '../lib/actions.js'
  import { ui } from '../lib/store.svelte.js'

  let clientId = $state('')
  let clientSecret = $state('')
  let error = $state('')

  async function handleSubmit() {
    error = ''
    try {
      await login(clientId, clientSecret)
    } catch (e) {
      error = e.message || 'Authentication failed'
    }
  }
</script>

<div class="min-h-screen flex items-center justify-center bg-gradient-to-br from-zinc-50 to-zinc-100">
  <div class="w-full max-w-sm">
    <div class="text-center mb-8">
      <img src="/images/logo/crystalbank-stacked-dark.svg" alt="CrystalBank" class="w-16 h-16 mb-4 mx-auto block">
      <h1 class="text-2xl font-bold text-zinc-900">CrystalBank</h1>
      <p class="text-sm text-zinc-500 mt-1">Sign in with your API credentials</p>
    </div>

    <div class="card p-6 shadow-sm">
      <form onsubmit={(e) => { e.preventDefault(); handleSubmit() }}>
        <div class="mb-4">
          <label class="field-label">Client ID</label>
          <input bind:value={clientId} type="text" class="field-input" placeholder="API key ID" required autocomplete="off">
        </div>
        <div class="mb-4">
          <label class="field-label">Client Secret</label>
          <input bind:value={clientSecret} type="password" class="field-input" placeholder="API key secret" required>
        </div>
        {#if error}
          <div class="mb-4 p-3 bg-red-50 border border-red-200 rounded-md text-sm text-red-700">{error}</div>
        {/if}
        <button type="submit" class="btn btn-primary w-full" disabled={ui.loading}>
          {#if ui.loading}
            <svg class="animate-spin" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M21 12a9 9 0 11-18 0 9 9 0 0118 0z" stroke-opacity="0.3"/>
              <path d="M21 12a9 9 0 00-9-9"/>
            </svg>
          {/if}
          {ui.loading ? 'Signing in...' : 'Sign in'}
        </button>
      </form>
    </div>

    <p class="text-center text-xs text-zinc-400 mt-4">CrystalBank &mdash; Event-sourced Banking Platform</p>
  </div>
</div>
