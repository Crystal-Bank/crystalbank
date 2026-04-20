<script>
  import { ui } from '../lib/store.svelte.js'
  import { logout, switchView } from '../lib/actions.js'

  function goToDashboard() {
    ui.permissionError = null
    switchView('dashboard')
  }

  function handleLogout() {
    ui.permissionError = null
    logout()
  }
</script>

{#if ui.permissionError}
  <div class="modal-backdrop" role="dialog" aria-modal="true" aria-labelledby="perm-err-title">
    <div class="modal-box" style="max-width: 420px;">
      <div style="display:flex; align-items:center; gap:0.75rem; margin-bottom:0.75rem;">
        <div style="flex-shrink:0; width:2.25rem; height:2.25rem; background:#fee2e2; border-radius:50%; display:flex; align-items:center; justify-content:center;">
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#b91c1c" stroke-width="2">
            <circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/>
          </svg>
        </div>
        <h2 id="perm-err-title" class="modal-title" style="margin-bottom:0;">Permission Denied</h2>
      </div>
      <p class="modal-desc">{ui.permissionError}</p>
      <p class="modal-desc" style="margin-top:-0.75rem;">Would you like to go to the dashboard or sign out?</p>
      <div style="display:flex; gap:0.75rem; justify-content:flex-end;">
        <button class="btn btn-ghost" onclick={handleLogout}>Sign out</button>
        <button class="btn btn-primary" onclick={goToDashboard}>Go to Dashboard</button>
      </div>
    </div>
  </div>
{/if}
