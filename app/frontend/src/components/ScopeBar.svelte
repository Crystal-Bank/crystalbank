<script>
  import { auth } from '../lib/store.svelte.js'
  import { setScope } from '../lib/actions.js'
  import { apiFetch } from '../lib/api.js'

  let scopeOptions = $state([])
  let showDropdown = $state(false)

  let suggestions = $derived(
    scopeOptions
      .filter(s => {
        const q = auth.scopeInput.toLowerCase()
        return q === '' || s.id.toLowerCase().includes(q) || s.name.toLowerCase().includes(q)
      })
      .slice(0, 8)
  )

  async function fetchScopes() {
    try {
      const res = await apiFetch('GET', '/scopes/?limit=200')
      scopeOptions = res.data.map(e => e.attributes)
    } catch { scopeOptions = [] }
  }

  function handleFocus() {
    showDropdown = true
    if (scopeOptions.length === 0) fetchScopes()
  }

  function handleChange() {
    setScope(auth.scopeInput)
  }

  function clearScope() {
    auth.scopeInput = ''
    setScope('')
  }

  function selectScope(scopeId) {
    auth.scopeInput = scopeId
    setScope(scopeId)
    showDropdown = false
  }
</script>

<div class="scope-bar" style="position:relative">
  <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="#71717a" stroke-width="2">
    <circle cx="12" cy="12" r="10"/><line x1="2" y1="12" x2="22" y2="12"/>
    <path d="M12 2a15.3 15.3 0 010 20M12 2a15.3 15.3 0 000 20"/>
  </svg>
  <div class="relative group">
    <span class="text-zinc-500 font-medium cursor-help">Scope:</span>
    <div class="absolute top-full left-0 mt-1 z-50 bg-zinc-800 text-white text-xs rounded-md p-3 w-80 hidden group-hover:block shadow-lg leading-relaxed pointer-events-none">
      Scopes are a mechanism to attach data ownership to entities on creation, they allow to filter out entities from API responses based on the users permissions on the respective scope. This model allows a strict control over the visibility of data points, based on the roles and permissions system
    </div>
  </div>
  <div class="relative flex-1 min-w-0">
    <input
      bind:value={auth.scopeInput}
      onchange={handleChange}
      oninput={handleChange}
      onfocus={handleFocus}
      onblur={() => setTimeout(() => { showDropdown = false }, 180)}
      type="text"
      placeholder="Enter scope UUID for write operations..."
      class="bg-transparent outline-none text-zinc-700 placeholder-zinc-400 w-full font-mono text-xs"
      style="border:none;padding:0;{auth.scopeInput ? 'padding-right:3.5rem;' : ''}"
    >
    {#if auth.scopeInput}
      <button
        onclick={clearScope}
        class="absolute right-0 top-1/2 -translate-y-1/2 text-zinc-400 hover:text-zinc-600 text-xs whitespace-nowrap"
      >&times; clear</button>
    {/if}
    {#if showDropdown && suggestions.length > 0}
      <div class="absolute top-full left-0 z-50 bg-white border border-zinc-200 rounded-md shadow-lg mt-1 min-w-72 max-h-48 overflow-y-auto">
        {#each suggestions as s (s.id)}
          <button
            type="button"
            class="w-full text-left px-3 py-2 hover:bg-zinc-50 border-b border-zinc-100 last:border-0"
            onmousedown={(e) => { e.preventDefault(); selectScope(s.id) }}
          >
            <div class="font-mono text-xs text-zinc-800 break-all">{s.id}</div>
            <div class="text-xs text-zinc-400 mt-0.5">{s.name}</div>
          </button>
        {/each}
      </div>
    {/if}
  </div>
</div>
