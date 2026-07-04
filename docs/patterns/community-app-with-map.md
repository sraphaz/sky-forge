# Community app with map — MVP tier

**app_types:** community, territorial  
**tier:** mvp-free  
**confidence:** curated

## Decisão

- Maps: OpenStreetMap + flutter_map (sem API key)
- Backend: Supabase (auth + postgres + storage)
- Site institucional: Astro estático na Vercel

## Trade-off conhecido

Geocoding gratuito tem rate limit; para >1000 pins considerar tier growth + Mapbox.

## Perguntas de intake sugeridas

- Pins são fixos ou editáveis por usuários?
- Precisa offline no mapa?
