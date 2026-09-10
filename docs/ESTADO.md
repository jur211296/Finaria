---
updated: 2026-09-10
tags: [now, punto-de-retomada]
---

# NOW — 2026-09-10 (Lima)

**Rama** `2.1` — Merges #128 y #129: el **paso 1** del rediseño, y el primero que toca producción
de verdad. TestFlight build **13** (CPV 13) — `VALID` e `IN_BETA_TESTING`.
**Subida Yala (TF/store) = solo Mini.**

## Esta sesión (paso 1: el percent de la elección nube)

**Para el usuario no cambia nada, y eso es lo que se buscaba.** Producción ya servía la card «Tu
cuenta en la nube» al 100 %, pero `gateway/wrangler.toml` decía `"0"`: el próximo `deploy` hecho por
cualquier otro motivo la habría apagado en todo el parque sin decisión de nadie. Ya dicen lo mismo,
**desplegado y comprobado con `curl` antes y después** (Version ID `e5f553f2`).

**El gateway ya NO te espera**: el deploy de producción está hecho. Y ojo con el cómo — va por
`npm run deploy:production`, nunca `wrangler` a pelo: su `predeploy` copia los dos manifests que
`src/` importa y que git ignora.

Los comentarios que describían producción al revés eran **nueve**, no los tres del ticket; uno
(`CloudRemoteConfig.swift`) no salía en su grep. Un guard nuevo en `gateway/test/config.test.ts` fija
los tres percents vivos leyendo el `.toml`, verificado con tres mutantes — pero **vive en la suite
que ningún workflow ejecuta**, igual que la red anti-brick de `MIN_SUPPORTED_BUILD`.

## Abiertos

1. **Tu cola física**: push APNs real (4), RPC de producción (3), sign-in real SIWA/Google (6), Apple
   Pay y carreras de red (4). Nada de eso se simula. Súmale los device-QA de los pasos 4, 5, 8, 9, 10.
2. **De FX quedan cuatro cosas**: el widget de inicio (simulable), el asistente (LLM real), la red
   (`ExchangeRateService` falla por AppAttest) y el seam `-uitest-preferred-currency`, que no existe.
3. **Tres veredictos de QA caducos**: `scheduled-payments-notif-dedup`,
   `welcome-start-fresh-wipes-before-ask` (el seam ya existe) y el callout de `siri-intent-dual-container`.
4. **CUATRO XCUITest en rojo** de la nocturna del 9-sep (**high**): caminos centrales, y la suite de UI
   ya no corre en los PR.
5. **Un markdown de encargo dispara la suite entera de iOS**
   (`encargos-markdown-triggers-the-whole-ios-suite`). Pasa en toda sesión lanzada.
6. **El aviso de cierre cita el PR de OTRA sesión** (medium): falla en silencio con `HTTP 200`.
7. **El build 13 llega al grupo interno, no al externo**: un segundo teléfono sin tu Apple ID no lo
   verá hasta pasar beta review.
8. **DMARC el 15-sep** · **cobertura de UI el 22-sep**. Esperan al calendario.

## Siguiente

**El paso 2 del runbook**, y luego los restantes en orden. **El 11 está vacante a propósito** y no se
renumera: las decisiones se citan entre sí por número. Los pasos 0 y 1 ya están en `done`.

**El board: 157 en backlog, 46 en qa** (`docs/TICKETS.md`, 261 = 261 contra disco). Los `high` fuera
del rediseño siguen siendo `nocturna-del-9-sep-…`, `chat-assistant-is-down` y
`siri-ai-integration-ios-27`.

## Bloqueo

**Dos cosas que te tocan a ti** (el deploy del gateway ya no está entre ellas): tras el fresh start,
tu iPhone quedará con sesión a una cuenta inexistente y **hay que recrear los grupos de prueba** antes
de los device-QA; y la política de privacidad y los términos **bloquean la publicación** del rediseño
(hoy dicen que Grupos viaja por iCloud).

**Nuevo, y con fecha de caducidad conocida:** con la card born-cloud ya visible, `welcome.new.privateBody`
promete «se sincronizan por tu iCloud privado» y en sesión de visita eso es falso. Su ticket está
**descartado a propósito** —el ADR retira M1— así que la ventana se cierra sola en el paso 12; si te
molesta antes, dilo.

**Decisiones tuyas que siguen abiertas**, ninguna del rediseño:
`corpus-de-test-de-staging-crece-sin-limite`, el filtro de naturaleza, los worktrees sin el candado
anti-atribución (`open-worktrees-lack-the-attribution-hook`), ¿se ataca ya el chat caído?, y si
`fab-appears-without-animation` sube de `low`. **Sin ticket y medido el 9-sep:** un CSV exportado antes
de convertir una cuenta ya no se importa a ella y aborta el fichero entero — dímelo si quieres uno.
