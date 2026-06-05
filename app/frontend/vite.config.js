import { execSync } from 'child_process'
import { defineConfig } from 'vite'
import { svelte } from '@sveltejs/vite-plugin-svelte'

const gitSha = process.env.GIT_SHA || (() => {
  try {
    return execSync('git rev-parse --short HEAD').toString().trim()
  } catch {
    return 'unknown'
  }
})()

export default defineConfig({
  define: {
    __GIT_SHA__: JSON.stringify(gitSha),
  },
  plugins: [svelte()],
  build: {
    outDir: '../public',
    emptyOutDir: false,
    rollupOptions: {
      output: {
        entryFileNames: 'app.js',
        chunkFileNames: 'app.js',
        assetFileNames: (assetInfo) => {
          if (assetInfo.name?.endsWith('.css')) return 'style.css'
          return '[name][extname]'
        },
      },
    },
  },
})
