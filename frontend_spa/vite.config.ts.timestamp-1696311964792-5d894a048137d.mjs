// vite.config.ts
import { defineConfig } from "file:///Users/jan/src/priv/shipvote/frontend_spa/node_modules/vite/dist/node/index.js";
import { svelte } from "file:///Users/jan/src/priv/shipvote/frontend_spa/node_modules/@sveltejs/vite-plugin-svelte/src/index.js";
import path from "path";
var __vite_injected_original_dirname = "/Users/jan/src/priv/shipvote/frontend_spa";
var vite_config_default = defineConfig({
  base: "",
  build: {
    outDir: "dist/",
    assetsDir: ".",
    rollupOptions: {
      input: {
        "video_overlay": path.resolve(__vite_injected_original_dirname, "src/apps/video_overlay/index.html"),
        "config": path.resolve(__vite_injected_original_dirname, "src/apps/config/index.html"),
        "live_config": path.resolve(__vite_injected_original_dirname, "src/apps/live_config/index.html"),
        "mobile": path.resolve(__vite_injected_original_dirname, "src/apps/mobile/index.html")
      },
      output: {
        chunkFileNames: `[name].js`
      }
    }
  },
  plugins: [svelte()]
});
export {
  vite_config_default as default
};
//# sourceMappingURL=data:application/json;base64,ewogICJ2ZXJzaW9uIjogMywKICAic291cmNlcyI6IFsidml0ZS5jb25maWcudHMiXSwKICAic291cmNlc0NvbnRlbnQiOiBbImNvbnN0IF9fdml0ZV9pbmplY3RlZF9vcmlnaW5hbF9kaXJuYW1lID0gXCIvVXNlcnMvamFuL3NyYy9wcml2L3NoaXB2b3RlL2Zyb250ZW5kX3NwYVwiO2NvbnN0IF9fdml0ZV9pbmplY3RlZF9vcmlnaW5hbF9maWxlbmFtZSA9IFwiL1VzZXJzL2phbi9zcmMvcHJpdi9zaGlwdm90ZS9mcm9udGVuZF9zcGEvdml0ZS5jb25maWcudHNcIjtjb25zdCBfX3ZpdGVfaW5qZWN0ZWRfb3JpZ2luYWxfaW1wb3J0X21ldGFfdXJsID0gXCJmaWxlOi8vL1VzZXJzL2phbi9zcmMvcHJpdi9zaGlwdm90ZS9mcm9udGVuZF9zcGEvdml0ZS5jb25maWcudHNcIjtpbXBvcnQgeyBkZWZpbmVDb25maWcgfSBmcm9tICd2aXRlJ1xuaW1wb3J0IHsgc3ZlbHRlIH0gZnJvbSAnQHN2ZWx0ZWpzL3ZpdGUtcGx1Z2luLXN2ZWx0ZSdcbmltcG9ydCBwYXRoIGZyb20gJ3BhdGgnXG5cbi8vIGh0dHBzOi8vdml0ZWpzLmRldi9jb25maWcvXG5leHBvcnQgZGVmYXVsdCBkZWZpbmVDb25maWcoe1xuICBiYXNlOiAnJyxcbiAgYnVpbGQ6IHtcbiAgICBvdXREaXI6ICdkaXN0LycsXG4gICAgYXNzZXRzRGlyOiAnLicsXG4gICAgcm9sbHVwT3B0aW9uczoge1xuICAgICAgaW5wdXQ6IHtcbiAgICAgICAgJ3ZpZGVvX292ZXJsYXknOiBwYXRoLnJlc29sdmUoX19kaXJuYW1lLCAnc3JjL2FwcHMvdmlkZW9fb3ZlcmxheS9pbmRleC5odG1sJyksXG4gICAgICAgICdjb25maWcnOiBwYXRoLnJlc29sdmUoX19kaXJuYW1lLCAnc3JjL2FwcHMvY29uZmlnL2luZGV4Lmh0bWwnKSxcbiAgICAgICAgJ2xpdmVfY29uZmlnJzogcGF0aC5yZXNvbHZlKF9fZGlybmFtZSwgJ3NyYy9hcHBzL2xpdmVfY29uZmlnL2luZGV4Lmh0bWwnKSxcbiAgICAgICAgJ21vYmlsZSc6IHBhdGgucmVzb2x2ZShfX2Rpcm5hbWUsICdzcmMvYXBwcy9tb2JpbGUvaW5kZXguaHRtbCcpLFxuICAgICAgfSxcbiAgICAgIG91dHB1dDoge1xuICAgICAgICBjaHVua0ZpbGVOYW1lczogYFtuYW1lXS5qc2AsXG4gICAgICB9XG4gICAgfSxcbiAgfSxcbiAgcGx1Z2luczogW3N2ZWx0ZSgpXVxufSk7XG4iXSwKICAibWFwcGluZ3MiOiAiO0FBQTZTLFNBQVMsb0JBQW9CO0FBQzFVLFNBQVMsY0FBYztBQUN2QixPQUFPLFVBQVU7QUFGakIsSUFBTSxtQ0FBbUM7QUFLekMsSUFBTyxzQkFBUSxhQUFhO0FBQUEsRUFDMUIsTUFBTTtBQUFBLEVBQ04sT0FBTztBQUFBLElBQ0wsUUFBUTtBQUFBLElBQ1IsV0FBVztBQUFBLElBQ1gsZUFBZTtBQUFBLE1BQ2IsT0FBTztBQUFBLFFBQ0wsaUJBQWlCLEtBQUssUUFBUSxrQ0FBVyxtQ0FBbUM7QUFBQSxRQUM1RSxVQUFVLEtBQUssUUFBUSxrQ0FBVyw0QkFBNEI7QUFBQSxRQUM5RCxlQUFlLEtBQUssUUFBUSxrQ0FBVyxpQ0FBaUM7QUFBQSxRQUN4RSxVQUFVLEtBQUssUUFBUSxrQ0FBVyw0QkFBNEI7QUFBQSxNQUNoRTtBQUFBLE1BQ0EsUUFBUTtBQUFBLFFBQ04sZ0JBQWdCO0FBQUEsTUFDbEI7QUFBQSxJQUNGO0FBQUEsRUFDRjtBQUFBLEVBQ0EsU0FBUyxDQUFDLE9BQU8sQ0FBQztBQUNwQixDQUFDOyIsCiAgIm5hbWVzIjogW10KfQo=
