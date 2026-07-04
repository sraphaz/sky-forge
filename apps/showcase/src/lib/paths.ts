/** Junta caminho interno com `base` do Astro (ex.: /sky-forge/projects/foo/). */
export function withBase(path: string): string {
  const normalized = path.startsWith("/") ? path : `/${path}`;
  const base = import.meta.env.BASE_URL.replace(/\/$/, "");
  return `${base}${normalized}`;
}
