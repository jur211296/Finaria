---
updated: 2026-09-08
tags: [now, punto-de-retomada]
---

# NOW — 2026-09-08 (Lima)

**Rama** `2.1` · HEAD `1bf08bb1` — Merge #108: la tasa falsa que el chat ya selló se corrige
TestFlight build **12** (CPV 12). **Subida Yala (TF/store) = solo Mini.**

## Esta sesión

**El gasto que quedó diciendo «1,0000» vuelve a enseñar su tipo de cambio real** (PR #108). El
arreglo hacia delante entró esta mañana, pero lo ya guardado no lo miraba nadie: el reparador solo
busca filas marcadas como aproximadas y el caso normal las sellaba en `false`, y el barrido que sí
reconoce esa forma es one-shot y ya había corrido. `fxOneToOneRepairSweep` sube a `.v2` — subir el
número rebobina el one-shot.

**Lo que vale es que el plan obvio hacía daño, y lo destapó la review adversarial.** Reabrir la fila
para que el reparador la recalcule es lo que hacía la `.v1`, y para este corpus es peor que no hacer
nada: aquellas filas tenían el importe convertido **crudo**, pero las del chat lo tienen **bien** y
solo miente la tasa — recalcular lo pisa con la conversión de hoy y, si la tasa de aquella fecha ya
no está en disco, baja hasta la tabla estática, un snapshot congelado. Ahora la tasa se **deduce de
los montos guardados** y se corrige en el sitio. De paso cierra una vía de re-envenenamiento:
reabrir emitía las cinco columnas del grupo `money` con la tasa mala todavía puesta y HLC fresco,
ganándole a un móvil que ya la hubiera reparado. 13 tests donde no había ninguno, 9 mutantes.

## Abiertos

1. **Device-QA** acumulado, ya son siete; **cinco son simulables**. El de hoy: fila con tasa
   `1,0000` en divisa ajena → tras arrancar enseña la tasa real, el importe **no** cambia y no sale
   el «≈». El de «≈» sigue siendo el único que **no** es simulable.
2. **DMARC el 15-sep** · **cobertura de UI el 22-sep**. Esperan al calendario, no a nadie.

## Siguiente

El device-QA, que ya cierra cinco de golpe.

## Bloqueo

**Las mismas cuatro decisiones tuyas**: `changing-an-account-currency-orphans-its-whole-history`
(**high** — editar la divisa de una cuenta deja su histórico entero en la vieja, en masa y sin
aviso), `el-hook-que-prohibe-atribuir-a-una-ia-no-corre-en-este-repo` (high, toca a todos los
agentes), `corpus-de-test-de-staging-crece-sin-limite` y el filtro de naturaleza.

De hoy salen tres tickets que **no** piden decisión: uno medium
(`fx-repair-sweep-seals-on-a-partially-restored-store` — ni el gate de quiescencia ni el guard de
presencia distinguen un restore a medias) y dos low.
