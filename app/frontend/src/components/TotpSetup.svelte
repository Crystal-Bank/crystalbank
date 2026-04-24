<script>
  import { onMount } from 'svelte'
  import { setupTotp, confirmTotp, addToast } from '../lib/actions.js'
  import { ui } from '../lib/store.svelte.js'

  let secret = $state('')
  let uri = $state('')
  let code = $state('')
  let error = $state('')
  let loading = $state(false)
  let loadError = $state('')

  onMount(async () => {
    try {
      const data = await setupTotp()
      secret = data.secret
      uri = data.uri
    } catch (e) {
      loadError = e.message || 'Failed to start TOTP setup'
    }
  })

  async function handleConfirm() {
    error = ''
    loading = true
    try {
      await confirmTotp(code)
      addToast('Two-factor authentication enabled')
      ui.view = 'dashboard'
      window.location.hash = 'dashboard'
    } catch (e) {
      error = e.message || 'Invalid code'
    } finally {
      loading = false
    }
  }
</script>

<div class="max-w-md mx-auto mt-8 p-6 card shadow-sm">
  <h2 class="text-lg font-semibold text-zinc-900 mb-1">Set up two-factor authentication</h2>
  <p class="text-sm text-zinc-500 mb-4">Scan the QR code with your authenticator app, then enter the 6-digit code to confirm.</p>

  {#if loadError}
    <p class="text-sm text-red-600">{loadError}</p>
  {:else if !secret}
    <p class="text-sm text-zinc-400">Loading…</p>
  {:else}
    <div class="mb-4">
      <img
        src={'https://api.qrserver.com/v1/create-qr-code/?size=180x180&data=' + encodeURIComponent(uri)}
        alt="TOTP QR code"
        class="mx-auto rounded"
        width="180" height="180"
      >
    </div>
    <p class="text-xs text-zinc-500 mb-1">Or enter this secret manually:</p>
    <p class="font-mono text-sm bg-zinc-100 rounded px-2 py-1 break-all mb-4">{secret}</p>

    <form onsubmit={(e) => { e.preventDefault(); handleConfirm() }}>
      <div class="mb-4">
        <label class="field-label">Verification code</label>
        <input bind:value={code} type="text" class="field-input" placeholder="6-digit code" maxlength="6" required autocomplete="one-time-code">
      </div>
      {#if error}
        <div class="mb-4 p-3 bg-red-50 border border-red-200 rounded-md text-sm text-red-700">{error}</div>
      {/if}
      <button type="submit" class="btn btn-primary w-full" disabled={loading}>
        {loading ? 'Verifying…' : 'Enable 2FA'}
      </button>
    </form>
  {/if}
</div>
