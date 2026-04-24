<script>
  import { setupPassword } from '../lib/actions.js'

  let { userId, token } = $props()

  let password = $state('')
  let confirm = $state('')
  let error = $state('')
  let success = $state(false)
  let loading = $state(false)

  async function handleSubmit() {
    error = ''
    if (password !== confirm) { error = 'Passwords do not match'; return }
    if (password.length < 8) { error = 'Password must be at least 8 characters'; return }
    loading = true
    try {
      await setupPassword(userId, token, password)
      success = true
    } catch (e) {
      error = e.message || 'Failed to set password'
    } finally {
      loading = false
    }
  }
</script>

<div class="min-h-screen flex items-center justify-center bg-gradient-to-br from-zinc-50 to-zinc-100">
  <div class="w-full max-w-sm">
    <div class="text-center mb-8">
      <h1 class="text-2xl font-bold text-zinc-900">CrystalBank</h1>
      <p class="text-sm text-zinc-500 mt-1">Set up your password</p>
    </div>

    <div class="card p-6 shadow-sm">
      {#if success}
        <p class="text-sm text-green-700 mb-4">Password set successfully. You can now sign in.</p>
        <a href="#" class="btn btn-primary w-full text-center block">Go to login</a>
      {:else}
        <form onsubmit={(e) => { e.preventDefault(); handleSubmit() }}>
          <div class="mb-4">
            <label class="field-label">New password</label>
            <input bind:value={password} type="password" class="field-input" placeholder="At least 8 characters" required>
          </div>
          <div class="mb-4">
            <label class="field-label">Confirm password</label>
            <input bind:value={confirm} type="password" class="field-input" placeholder="Repeat password" required>
          </div>
          {#if error}
            <div class="mb-4 p-3 bg-red-50 border border-red-200 rounded-md text-sm text-red-700">{error}</div>
          {/if}
          <button type="submit" class="btn btn-primary w-full" disabled={loading}>
            {loading ? 'Setting password…' : 'Set password'}
          </button>
        </form>
      {/if}
    </div>
  </div>
</div>
