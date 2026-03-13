<script>
  import { NAV_SECTIONS } from '../lib/store.svelte.js'
  import { switchView, logout } from '../lib/actions.js'

  let { currentView } = $props()
</script>

<aside class="w-56 bg-zinc-900 flex flex-col flex-shrink-0 overflow-y-auto">
  <div class="px-4 py-5 border-b border-zinc-800">
    <div class="flex items-center gap-2.5">
      <img src="/crystalbank-logo.png" alt="CrystalBank" class="w-7 h-7 rounded-lg flex-shrink-0 object-cover">
      <div>
        <div class="text-sm font-semibold text-white leading-tight">CrystalBank</div>
        <div class="text-xs text-zinc-500 leading-tight">Dashboard</div>
      </div>
    </div>
  </div>

  <nav class="flex-1 px-3 py-3 space-y-4">
    {#each NAV_SECTIONS as section (section.label)}
      <div>
        <div class="px-2 mb-1 text-xs font-semibold uppercase tracking-wider text-zinc-500">
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

  <div class="px-3 py-3 border-t border-zinc-800">
    <button onclick={logout} class="nav-link w-full text-left">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <path d="M9 21H5a2 2 0 01-2-2V5a2 2 0 012-2h4M16 17l5-5-5-5M21 12H9"/>
      </svg>
      Sign out
    </button>
  </div>
</aside>
