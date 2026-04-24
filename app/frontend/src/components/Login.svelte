<script>
  import { loginWithPassword } from '../lib/actions.js'
  import { ui } from '../lib/store.svelte.js'

  let email = $state('')
  let password = $state('')
  let totpCode = $state('')
  let totpRequired = $state(false)
  let error = $state('')

  async function handleSubmit() {
    error = ''
    try {
      const result = await loginWithPassword(email, password, totpRequired ? totpCode : null)
      if (result?.totp_required) {
        totpRequired = true
        error = 'Enter the code from your authenticator app.'
      }
    } catch (e) {
      error = e.message || 'Authentication failed'
    }
  }
</script>

<div class="min-h-screen flex items-center justify-center bg-gradient-to-br from-zinc-50 to-zinc-100">
  <div class="w-full max-w-sm">
    <div class="text-center mb-8">
      <img src="/images/logo/crystalbank-stacked-dark.svg" alt="CrystalBank" class="w-32 h-32 mb-4 mx-auto block">
      <p class="text-sm text-zinc-500 mt-1">Sign in to your account</p>
    </div>

    <div class="card p-6 shadow-sm">
      <form onsubmit={(e) => { e.preventDefault(); handleSubmit() }}>
        {#if !totpRequired}
          <div class="mb-4">
            <label class="field-label">Email</label>
            <input bind:value={email} type="email" class="field-input" placeholder="you@example.com" required autocomplete="email">
          </div>
          <div class="mb-4">
            <label class="field-label">Password</label>
            <input bind:value={password} type="password" class="field-input" placeholder="Your password" required autocomplete="current-password">
          </div>
        {:else}
          <div class="mb-4">
            <label class="field-label">Authenticator code</label>
            <input bind:value={totpCode} type="text" class="field-input" placeholder="6-digit code" required autocomplete="one-time-code" maxlength="6">
          </div>
        {/if}

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
          {ui.loading ? 'Signing in...' : totpRequired ? 'Verify' : 'Sign in'}
        </button>

        {#if totpRequired}
          <button type="button" class="mt-2 text-sm text-zinc-500 w-full text-center hover:underline" onclick={() => { totpRequired = false; totpCode = ''; error = '' }}>
            Back to login
          </button>
        {:else}
          <div class="mt-4 text-center">
            <a href="#forgot-password" class="text-sm text-zinc-500 hover:underline">Forgot password?</a>
          </div>
        {/if}
      </form>
    </div>

    <p class="text-center text-xs text-zinc-400 mt-4">CrystalBank &mdash; Event-sourced Banking Platform</p>
  </div>
</div>
