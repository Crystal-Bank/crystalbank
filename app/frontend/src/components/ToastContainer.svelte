<script>
  import { ui } from '../lib/store.svelte.js'
</script>

<div class="toast-wrap" aria-live="polite">
  {#each ui.toasts as t (t.id)}
    <div class="toast" class:toast-error={t.type === 'error'} class:toast-success={t.type !== 'error'}>
      {t.msg}
    </div>
  {/each}
</div>
