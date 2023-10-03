import { defineConfig } from 'vite'
import { svelte } from '@sveltejs/vite-plugin-svelte'
import path from 'path'

// https://vitejs.dev/config/
export default defineConfig({
  base: '',
  build: {
    minify: false,
    outDir: 'dist/',
    assetsDir: '.',
    rollupOptions: {
      input: {
        'video_overlay': path.resolve(__dirname, 'src/apps/video_overlay/index.html'),
        'config': path.resolve(__dirname, 'src/apps/config/index.html'),
        'live_config': path.resolve(__dirname, 'src/apps/live_config/index.html'),
        'mobile': path.resolve(__dirname, 'src/apps/mobile/index.html'),
      },
      output: {
        chunkFileNames: `[name].js`,
      }
    },
  },
  plugins: [svelte()]
});
