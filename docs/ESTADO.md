---
updated: 2026-09-09
tags: [now, punto-de-retomada]
---

# NOW — 2026-09-09 (Lima)

**Rama** `2.1` · HEAD `b2744915` — Merge #110: el bulk de cuenta y la divisa vieja
TestFlight build **12** (CPV 12). **Subida Yala (TF/store) = solo Mini.**

## Esta sesión

**El primer medium de la cola, cerrado borrando en vez de parcheando** (PR #110).
`TransactionService.bulkUpdateAccount` **nunca tuvo un llamador en toda la historia del repo** y
divergía de la ruta viva en **dos** cosas, no en la una reportada: tampoco bloqueaba transferencias.
Los tests van contra la ruta que la app ejecuta de verdad, que no tenía ninguno, más un source-scan
que vigila que el método no vuelva. Detalle completo en el ticket y en el PR.

**Tres cosas que cambian cómo se diagnostica esta familia, y por eso están aquí y no solo en el
ticket:**

1. Cambiar `currencyCode` **no emite un grupo `money` aparentemente coherente**: no emite el grupo en
   absoluto (ni esa columna ni `account_ref` pertenecen a grupo, así que `DeltaEmitter` deja
   `touchedGroups` vacío y el guard del canario ni se evalúa). Dos tickets lo tenían al revés.
2. **El bloque bulk de `TransactionService` está muerto entero**: seis operaciones, cero llamadores;
   los únicos usos vivos del servicio son `setContext` y `create`.
3. **Al BORRAR código con cuerpo, la suite completa antes de sellar.** Un source-scan del widget
   cuenta call-sites de `WidgetDataCache.updateCache(` y el método borrado tenía uno (49 → 48). El
   mapeo del gate va por nombre de clase y ese scan vigila un área sin relación: por construcción no
   lo alcanzaba, y la review adversarial tampoco lo vio.

## Abiertos

1. **La cola física de Jürgen**, agrupada por lo que de verdad la bloquea: push APNs real (4
   tickets), RPC de producción (3), sign-in real SIWA/Google (6), Apple Pay y carreras de red (4).
   Nada de eso se simula; lo demás sí.
2. **50 tickets siguen en `qa/`**, buena parte simulables. Cuatro de FX están bloqueados por
   `qa-no-puede-crear-cuenta-en-otra-divisa` (**high**): el selector de moneda no responde a la
   automatización —no es un bug de la app, se comprobó con dos controles— y con un launch arg que
   siembre una cuenta en divisa ausente se cierran los cuatro.
3. **Tres veredictos de QA escritos en sus propios tickets están caducos**:
   `scheduled-payments-notif-dedup` y `welcome-start-fresh-wipes-before-ask` pedían un seam que **ya
   existe**, y el callout de `siri-intent-dual-container` lo refuta su ticket hermano.
4. **El avisador de rojos advisory del CI no puede avisar** (`ci-avisador-de-rojos-advisory-tiene-la-clave-mal`,
   **high**, nuevo): `Invalid API key`. Los 12 runs anteriores salían verdes porque nunca hubo un
   advisory en rojo que avisar — la primera vez que hizo falta, no funcionó. Mientras siga así, un
   `tests: fail` no distingue «hay tests rotos» de «la credencial está mal».
5. **DMARC el 15-sep** · **cobertura de UI el 22-sep**. Esperan al calendario, no a nadie.

## Siguiente

El siguiente medium de la cola: `fx-approximate-mark-missing-on-secondary-surfaces`, y después
`bridge-de-grupos-pierde-la-marca-de-sus-patas`.

## Bloqueo

**Las mismas cuatro decisiones tuyas**: `changing-an-account-currency-orphans-its-whole-history`
(**high** — editar la divisa de una cuenta deja su histórico entero en la vieja, en masa y sin
aviso; sigue siendo el hueco grande de esta familia), `el-hook-que-prohibe-atribuir-a-una-ia-no-corre-en-este-repo`
(**high**, toca a todos los agentes — **re-comprobado el 9-sep: no hay `commit-msg` en ninguno de los
dos árboles y el `settings.json` global no lo declara**; los cuatro commits de esta sesión se
verificaron con un grep a mano), `corpus-de-test-de-staging-crece-sin-limite` y el filtro de
naturaleza.
