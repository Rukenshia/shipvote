import { sveltekit } from '@sveltejs/kit/vite';
import path from 'path';
import { fileURLToPath } from 'url';

/** @type {import('vite').UserConfig} */
const config = {
  plugins: [sveltekit()],
  resolve: {
    alias: {
      $src: path.resolve(path.dirname(fileURLToPath(import.meta.url)), 'src'),
      $lib: path.resolve(path.dirname(fileURLToPath(import.meta.url)), 'lib')
    }
  },

  server: {
    cors: true
  }
};

export default config;
