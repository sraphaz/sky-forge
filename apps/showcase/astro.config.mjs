import { defineConfig } from "astro/config";
import skyLocalApi from "./integrations/sky-local-api.mjs";

export default defineConfig({
  site: "https://sraphaz.github.io",
  base: "/sky-forge",
  srcDir: "src",
  outDir: "dist",
  // Endpoints de decisão só existem no dev server; o build estático não muda.
  integrations: [skyLocalApi()],
  server: {
    port: 4321,
    strictPort: true,
  },
});
