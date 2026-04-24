<script>
  import { requestPasswordReset } from '../lib/actions.js'

  let email = $state('')
  let error = $state('')
  let submitted = $state(false)
  let loading = $state(false)

  async function handleSubmit() {
    error = ''
    loading = true
    try {
      await requestPasswordReset(email)
      submitted = true
    } catch (e) {
      error = e.message || 'Request failed'
    } finally {
      loading = false
    }
  }
</script>

<div class="min-h-screen flex items-center justify-center bg-gradient-to-br from-zinc-50 to-zinc-100">
  <div class="w-full max-w-sm">
    <div class="text-center mb-8">
      <h1 class="text-2xl font-bold text-zinc-900">CrystalBank</h1>
      <p class="text-sm text-zinc-500 mt-1">Reset your password</p>
    </div>

    <div class="card p-6 shadow-sm">
      {#if submitted}
        <p class="text-sm text-green-700">If an account with that email exists, you will receive a reset link shortly.</p>
      {:else}
        <form onsubmit={(e) => { e.preventDefault(); handleSubmit() }}>
          <div class="mb-4">
            <label class="field-label">Email</label>
            <input bind:value={email} type="email" class="field-input" placeholder="you@example.com" required autocomplete="email">
          </div>
          {#if error}
            <div class="mb-4 p-3 bg-red-50 border border-red-200 rounded-md text-sm text-red-700">{error}</div>
          {/if}
          <button type="submit" class="btn btn-primary w-full" disabled={loading}>
            {loading ? 'Sending…' : 'Send reset link'}
          </button>
        </form>
      {/if}
      <div class="mt-4 text-center">
        <a href="#" class="text-sm text-zinc-500 hover:underline">Back to login</a>
      </div>
    </div>
  </div>
</div>
