---
updated: 2026-09-10
tags: [now, punto-de-retomada]
---

# NOW — 2026-09-10 (Lima)

**Rama** `2.1` — Merge #130: el **paso 2** del rediseño de sesiones. TestFlight build **13** (CPV 13).
**Subida Yala (TF/store) = solo Mini.**

## Esta sesión (paso 2: el tipo de cuenta)

**El backend ya sabe si una cuenta lleva tus finanzas o solo tus grupos** (`profiles.kind`), y
`GET /account/exists` lo dice. Aplicado en **staging y producción**, con los tres md5 idénticos en los
dos entornos. Para el usuario **todavía no cambia nada**: quién usa ese dato para elegir pantalla es el
paso 3.

**Producción está a cero.** El fresh start que decidiste: 1 155 filas y las 2 identidades, borradas y
verificadas. `auth.audit_log_entries` y `auth.flow_state` se midieron por si guardaban PII: estaban
vacías, así que no se amplió el alcance.

Lo que la medición cambió del plan: `kind` **no** era la segunda verdad que la decisión asumía —una
cuenta que vuelve a iCloud conserva `personal_claimed_at` y aun así es `groups_only`, y se vio ocurrir
en staging—; los grants de `profiles` son a nivel TABLA, así que sin un trigger la columna habría sido
auto-servible; y el backfill quedó acotado a la primera aplicación, porque re-aplicarlo habría
deshecho degradaciones legítimas en silencio.

## Tu cola

1. **Tu iPhone apunta a una cuenta que ya no existe**, y no falla en silencio: mientras el JWT viva,
   cada llamada da 409/502. **Cierra sesión, vuelve a entrar y recrea los grupos de prueba** antes de
   los device-QA de los pasos 5, 8, 9 y 10.
2. **Desplegar el Worker** a staging y a producción — la base ya está en los dos. **La base va SIEMPRE
   antes que su Worker**; al revés, pide una columna que no existe y devuelve 502 en cada sign-in. Por
   `npm run deploy:production`, nunca `wrangler` a pelo.
3. **Física, la de siempre**: push APNs real (4), RPC de producción (3), sign-in real SIWA/Google (6),
   Apple Pay y carreras de red (4). Más los device-QA de los pasos 4, 5, 8, 9 y 10.
4. **De FX quedan cuatro**: widget de inicio (simulable), asistente (LLM real), red (`ExchangeRateService`
   por AppAttest) y el seam `-uitest-preferred-currency`, que no existe.
5. **Tres veredictos de QA caducos** · **el build 13 no llega al grupo externo** hasta pasar beta review.
6. **DMARC el 15-sep** · **cobertura de UI el 22-sep**. Esperan al calendario.

## Siguiente

**El paso 3 del runbook** (`cloud-sign-in-discovers-account-kind`), que es quien convierte el dato
nuevo en ruteo. **El 11 sigue vacante a propósito.** Pasos 0, 1 y 2 ya están cerrados.

**El board: 157 en backlog, 47 en qa** (262 = 262 contra disco).

## Bloqueo

**Los goldens de grupos ya no dan señal** (`corpus-de-test-de-staging-crece-sin-limite`, subido a
**high**): 10 de 25 fallan por timeout, con 702 grupos activos para un usuario de test y `split_groups`
creciendo 59 en una sola sesión. Descartado que sea del cambio de hoy, con control. Hasta que el corpus
se acote, un rojo ahí no distingue código roto de corpus grande.

**Y una decisión tuya, nueva** (`reverse-cutover-cerrado-para-cuentas-born-cloud`, **high**): la
degradación a solo-grupos ya funciona, pero la puerta que lleva a ella exige `migrated_at` y **ninguna
cuenta nacida en la nube lo tiene** — tras el fresh start, el 100 % de producción. La fila E de la
matriz promete un «Volver a iCloud» que hoy no puede recorrer nadie.

**Sigue en pie:** la política de privacidad y los términos **bloquean la publicación** del rediseño (hoy
dicen que Grupos viaja por iCloud). Y las decisiones tuyas de antes: el filtro de naturaleza, los
worktrees sin candado anti-atribución, ¿se ataca ya el chat caído?, y si `fab-appears-without-animation`
sube de `low`. **Sin ticket, medido el 9-sep:** un CSV exportado antes de convertir una cuenta ya no se
importa a ella y aborta el fichero entero.
