---
updated: 2026-09-08
tags: [now, punto-de-retomada]
---

# NOW — 2026-09-08 (Lima)

**Rama** `2.1` · HEAD `7897046a` — Merge #109: barrido de QA en simulador
TestFlight build **12** (CPV 12). **Subida Yala (TF/store) = solo Mini.**

## Esta sesión

**Diez tickets de `qa/` cerrados con evidencia en pantalla** (PR #109), ninguno por inferencia de
código. Panel, Estadísticas, Grupos, la card de P&L cambiario y el banner de actualización. Donde
se pudo, el testigo es aritmético y no una captura: `8.132,00 ÷ 31 = 262,32` (con el día perdido
daría 271,07), `2.000 × (3,66 − 3,70) = −80,00`, y los netos del resumen de grupo cuadrando con la
cabecera.

**Lo que vale de verdad: tres premisas del board eran falsas, y las tres inflaban el device-QA.**
«Ningún seed es multi-divisa» → `DevSeedAccounts` crea cuenta **PEN y USD**. «No hay histórico con
una fila incompleta» → las filas sembradas traen solo PEN/EUR/USD de 48 divisas, o sea parciales
**por construcción**. «La card de P&L no aparece en simulador» → sale con el seed `minimal`. Este
mismo documento repetía la primera, y por eso siete device-QA parecían de Jürgen.

## Abiertos

1. **La cola física de Jürgen**, ya agrupada por lo que de verdad la bloquea: push APNs real (4
   tickets), RPC de producción (3), sign-in real SIWA/Google (6), Apple Pay y carreras de red (4).
   Nada de eso se simula; lo demás sí.
2. **50 tickets siguen en `qa/`**, buena parte simulables. Cuatro de FX están bloqueados por
   `qa-no-puede-crear-cuenta-en-otra-divisa` (**high**): el selector de moneda no responde a la
   automatización —no es un bug de la app, se comprobó con dos controles— y con un launch arg que
   siembre una cuenta en divisa ausente se cierran los cuatro.
3. **Tres veredictos de QA escritos en sus propios tickets están caducos**:
   `scheduled-payments-notif-dedup` y `welcome-start-fresh-wipes-before-ask` pedían un seam que **ya
   existe**, y el callout de `siri-intent-dual-container` lo refuta su ticket hermano.
4. **DMARC el 15-sep** · **cobertura de UI el 22-sep**. Esperan al calendario, no a nadie.

## Siguiente

Los mediums, empezando por `bulk-update-account-leaves-converted-amount-stale`.

## Bloqueo

**Las mismas cuatro decisiones tuyas**: `changing-an-account-currency-orphans-its-whole-history`
(**high** — editar la divisa de una cuenta deja su histórico entero en la vieja, en masa y sin
aviso), `el-hook-que-prohibe-atribuir-a-una-ia-no-corre-en-este-repo` (high, toca a todos los
agentes), `corpus-de-test-de-staging-crece-sin-limite` y el filtro de naturaleza.
