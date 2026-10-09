import { defineConfig } from 'vite';

export default defineConfig({
  base: './',
  server: {
    port: 4000,
    open: true,
  },
  build: {
    outDir: 'dist',
  },
});
