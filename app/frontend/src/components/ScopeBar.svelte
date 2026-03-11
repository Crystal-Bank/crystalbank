<script>
  import { auth } from '../lib/store.svelte.js'
  import { setScope } from '../lib/actions.js'

  function handleChange() {
    setScope(auth.scopeInput)
  }

  function clearScope() {
    auth.scopeInput = ''
    setScope('')
  }
</script>

<div class="scope-bar">
  <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="#71717a" stroke-width="2">
    <circle cx="12" cy="12" r="10"/><line x1="2" y1="12" x2="22" y2="12"/>
    <path d="M12 2a15.3 15.3 0 010 20M12 2a15.3 15.3 0 000 20"/>
  </svg>
  <span class="text-zinc-500 font-medium">Scope:</span>
  <input
    bind:value={auth.scopeInput}
    onchange={handleChange}
    type="text"
    placeholder="Enter scope UUID for write operations..."
    class="bg-transparent outline-none text-zinc-700 placeholder-zinc-400 flex-1 min-w-0 font-mono text-xs"
    style="border:none;padding:0;"
  >
  {#if auth.scopeInput}
    <button onclick={clearScope} class="text-zinc-400 hover:text-zinc-600 text-xs">&times; clear</button>
  {/if}
</div>
