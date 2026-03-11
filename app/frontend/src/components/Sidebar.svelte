<script>
  import { NAV_ITEMS } from '../lib/store.svelte.js'
  import { switchView, logout } from '../lib/actions.js'

  let { currentView } = $props()
</script>

<aside class="w-56 bg-zinc-900 flex flex-col flex-shrink-0 overflow-y-auto">
  <div class="px-4 py-5 border-b border-zinc-800">
    <div class="flex items-center gap-2.5">
      <div class="w-7 h-7 bg-white rounded-lg flex items-center justify-center flex-shrink-0">
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#18181b" stroke-width="2.5">
          <path d="M3 9l9-7 9 7v11a2 2 0 01-2 2H5a2 2 0 01-2-2z"/>
        </svg>
      </div>
      <div>
        <div class="text-sm font-semibold text-white leading-tight">CrystalBank</div>
        <div class="text-xs text-zinc-500 leading-tight">Dashboard</div>
      </div>
    </div>
  </div>

  <nav class="flex-1 px-3 py-3 space-y-0.5">
    {#each NAV_ITEMS as item (item.id)}
      <a class="nav-link" class:active={currentView === item.id} onclick={() => switchView(item.id)}>
        {@html item.icon}
        <span>{item.label}</span>
      </a>
    {/each}
  </nav>

  <div class="px-3 py-3 border-t border-zinc-800">
    <button onclick={logout} class="nav-link w-full text-left">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <path d="M9 21H5a2 2 0 01-2-2V5a2 2 0 012-2h4M16 17l5-5-5-5M21 12H9"/>
      </svg>
      Sign out
    </button>
  </div>
</aside>
