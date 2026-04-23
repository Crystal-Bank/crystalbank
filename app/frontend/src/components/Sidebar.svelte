<script>
  import { NAV_SECTIONS, auth } from '../lib/store.svelte.js'
  import { switchView, logout, setScope } from '../lib/actions.js'
  import { apiFetch } from '../lib/api.js'
  import { onMount } from 'svelte'

  let { currentView } = $props()

  let scopeOptions = $state([])
  let scopesFetched = $state(false)
  let showDropdown = $state(false)
  let switcherEl = $state(null)

  let canSwitch = $derived(scopesFetched && scopeOptions.length > 0)

  // Position for the fixed dropdown
  let dropdownTop = $state(0)
  let dropdownLeft = $state(0)

  let currentScopeName = $derived(
    auth.scope
      ? (scopeOptions.find(s => s.id === auth.scope)?.name || auth.scope.slice(0, 8) + '…')
      : '…'
  )

  // Build a flat list ordered by tree depth (root → children), with depth info
  let flatTree = $derived.by(() => {
    if (scopeOptions.length === 0) return []

    const map = {}
    scopeOptions.forEach(s => { map[s.id] = { ...s, children: [] } })

    const roots = []
    scopeOptions.forEach(s => {
      if (s.parent_scope_id && map[s.parent_scope_id]) {
        map[s.parent_scope_id].children.push(map[s.id])
      } else {
        roots.push(map[s.id])
      }
    })

    const result = []
    function walk(nodes, depth) {
      nodes.forEach(n => {
        result.push({ id: n.id, name: n.name, depth })
        if (n.children.length) walk(n.children, depth + 1)
      })
    }
    walk(roots, 0)
    return result
  })

  async function fetchScopes() {
    let meScope = null
    try {
      const me = await apiFetch('GET', '/me/', null, { scope: false })
      if (me.scope) meScope = { id: me.scope.id, name: me.scope.name }
    } catch {}

    try {
      const res = await apiFetch('GET', '/scopes/?limit=200', null, { scope: false })
      const scopes = res.data.map(e => e.attributes).filter(s => s.status !== 'pending_approval')
      if (meScope && !scopes.find(s => s.id === meScope.id)) {
        scopes.push(meScope)
      }
      scopeOptions = scopes
      if (!auth.scope) {
        const root = scopeOptions.find(s => !s.parent_scope_id)
        if (root) setScope(root.id)
      }
    } catch {
      scopeOptions = meScope ? [meScope] : []
      if (meScope && !auth.scope) setScope(meScope.id)
    }

    scopesFetched = true
  }

  // Always fetch on mount: resolves the active scope name and determines
  // whether the switcher should be interactive.
  onMount(fetchScopes)

  function toggleDropdown() {
    if (!showDropdown) {
      if (switcherEl) {
        const rect = switcherEl.getBoundingClientRect()
        dropdownTop = rect.bottom + 6
        dropdownLeft = rect.left
      }
    }
    showDropdown = !showDropdown
  }

  function selectScope(scopeId) {
    setScope(scopeId)
    showDropdown = false
  }
</script>

<aside class="w-56 bg-brand-deep-navy flex flex-col flex-shrink-0">
  <!-- Invisible overlay to close dropdown when clicking outside -->
  {#if showDropdown}
    <div class="fixed inset-0 z-40" onclick={() => showDropdown = false}></div>
  {/if}

  <!-- Sidebar Header -->
  <div class="px-3 pt-3 pb-2 border-b border-brand-navy-mid" bind:this={switcherEl}>
    <!-- App branding -->
    <div class="flex items-center gap-2 px-1 mb-3">
      <img src="/images/logo/crystalbank-horizontal-dark.svg" alt="CrystalBank" class="h-7 w-auto flex-shrink-0">
    </div>

    <!-- Scope / Company Switcher Button -->
    {#if canSwitch}
    <div class="relative group mb-1">
      <button
        onclick={toggleDropdown}
        class="w-full flex items-center gap-2 px-2 py-2 rounded-md transition-colors text-left"
        style="background: {showDropdown ? 'rgba(255,255,255,0.1)' : 'transparent'}"
        onmouseenter={(e) => { if (!showDropdown) e.currentTarget.style.background = 'rgba(255,255,255,0.06)' }}
        onmouseleave={(e) => { if (!showDropdown) e.currentTarget.style.background = 'transparent' }}
      >
        <!-- Scope Icon -->
        <div class="w-6 h-6 rounded bg-brand-navy-mid flex items-center justify-center flex-shrink-0">
          <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="rgba(255,255,255,0.7)" stroke-width="2">
            <circle cx="12" cy="12" r="10"/><line x1="2" y1="12" x2="22" y2="12"/>
            <path d="M12 2a15.3 15.3 0 010 20M12 2a15.3 15.3 0 000 20"/>
          </svg>
        </div>
        <!-- Scope Name -->
        <span class="flex-1 text-sm font-medium text-white truncate leading-tight">{currentScopeName}</span>
        <!-- Chevrons icon -->
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="rgba(255,255,255,0.4)" stroke-width="2">
          <path d="M8 9l4-4 4 4M16 15l-4 4-4-4"/>
        </svg>
      </button>
      {#if auth.scope}
        <div class="absolute left-full top-1/2 -translate-y-1/2 ml-2 z-50 bg-brand-deep-navy border border-brand-navy-mid text-brand-off-white text-xs font-mono rounded px-2.5 py-1.5 whitespace-nowrap shadow-lg pointer-events-none hidden group-hover:block">
          {auth.scope}
        </div>
      {/if}
    </div>
    {/if}
  </div>

  <!-- Dropdown Menu — fixed position so it floats over the layout -->
  {#if showDropdown}
    <div
      class="fixed z-50 bg-brand-navy-mid border border-white/10 rounded-lg shadow-2xl overflow-hidden"
      style="top: {dropdownTop}px; left: {dropdownLeft}px; min-width: 260px; max-width: 340px;"
    >
      {#if flatTree.length > 0}
        <div class="max-h-72 overflow-y-auto py-1">
          {#each flatTree as s (s.id)}
            <button
              type="button"
              onclick={() => selectScope(s.id)}
              class="w-full flex items-center gap-2 text-left"
              style="background: {auth.scope === s.id ? 'rgba(255,255,255,0.08)' : 'transparent'}; padding: 0.4rem 0.75rem 0.4rem {0.75 + s.depth * 1.25}rem;"
              onmouseenter={(e) => { e.currentTarget.style.background = 'rgba(255,255,255,0.08)' }}
              onmouseleave={(e) => { e.currentTarget.style.background = auth.scope === s.id ? 'rgba(255,255,255,0.08)' : 'transparent' }}
            >
              {#if s.depth > 0}
                <!-- Tree connector line -->
                <svg width="10" height="16" viewBox="0 0 10 16" fill="none" class="flex-shrink-0 -ml-0.5">
                  <path d="M1 0 L1 8 L9 8" stroke="rgba(255,255,255,0.18)" stroke-width="1.5" fill="none"/>
                </svg>
              {/if}
              <div
                class="flex-shrink-0 rounded flex items-center justify-center text-white font-semibold"
                style="width:1.25rem; height:1.25rem; background: rgba(255,255,255,0.12); font-size:0.6rem;"
              >
                {s.name ? s.name[0].toUpperCase() : '?'}
              </div>
              <span class="flex-1 text-sm text-brand-off-white truncate">{s.name}</span>
              {#if auth.scope === s.id}
                <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="rgba(255,255,255,0.55)" stroke-width="2.5">
                  <path d="M20 6L9 17l-5-5"/>
                </svg>
              {/if}
            </button>
          {/each}
        </div>
      {:else}
        <div class="px-3 py-3 text-xs text-brand-crystal-glow/50 text-center">Loading scopes…</div>
      {/if}
    </div>
  {/if}

  <nav class="flex-1 px-3 py-3 space-y-4 overflow-y-auto">
    {#each NAV_SECTIONS as section (section.label)}
      <div>
        <div class="px-2 mb-1 text-xs font-semibold uppercase tracking-wider text-brand-crystal-glow/50">
          {section.label}
        </div>
        <div class="space-y-0.5">
          {#each section.items as item (item.id)}
            <a class="nav-link" class:active={currentView === item.id} onclick={() => switchView(item.id)}>
              {@html item.icon}
              <span>{item.label}</span>
            </a>
          {/each}
        </div>
      </div>
    {/each}
  </nav>

  <div class="px-3 py-3 border-t border-brand-navy-mid">
    <button onclick={logout} class="nav-link w-full text-left">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <path d="M9 21H5a2 2 0 01-2-2V5a2 2 0 012-2h4M16 17l5-5-5-5M21 12H9"/>
      </svg>
      Sign out
    </button>
  </div>
</aside>
