---
updated: 2026-09-08
tags: [now, punto-de-retomada]
---

# NOW — 2026-09-08 (Lima)

**Rama** `2.1` · HEAD `c11a386d` — Merge #105: memoria de Frank tras los goldens
TestFlight build **12** (CPV 12). **Subida Yala (TF/store) = solo Mini.**

## Esta sesión

**Los goldens de staging vuelven a dar 25/25** (PR #104). Los dos rojos eran de **aserción**, no
timeouts: el bump de canon a `c2` del 7-sep no actualizó dos asserts que seguían pidiendo `c1`. Pasó
24 h invisible porque el CI no corre ni un test del gateway **y** la copia del manifest está
gitignoreada — con `npx vitest` se medía con el contrato viejo y el assert pasaba. Cerrado con un
guard offline de 2 ms (`manifest.sync.test.ts`).

**Los 10 timeouts NO se reproducen, y se dice como es** en vez de inventarles causa. Lo medido es el
margen: el golden más ajustado usa el **55 %** de su timeout. Instrumentar `fetch` dio en una corrida
lo que cuatro hipótesis no dieron — 32 793 peticiones, y la fórmula: un pull cuesta `1 + 5×N` por
grupo, haya o no algo que traer. El ticket traía cuatro premisas falsas, tres de ellas dirigiendo el
trabajo al sitio equivocado; están escritas en el ticket cerrado.

## Abiertos

1. **Device-QA** acumulado: dueño atrapado, recordatorio y «≈» (éste **no es simulable**), el signo
   del chat de #102 y el barrido de #103 — los dos **sí** lo son: dictar un gasto y mirar el saldo
   antes y después del primer arranque. El barrido imprime en DEBUG cuántas filas curó, que es el
   número que nunca se pudo medir desde el repo.
2. **DMARC el 15-sep** · **cobertura de UI el 22-sep**. Esperan al calendario, no a nadie.

## Siguiente

El device-QA, que ya acumula cuatro tickets y cierra dos de golpe.

## Bloqueo

**Una decisión tuya, sin prisa:** `corpus-de-test-de-staging-crece-sin-limite`. Los usuarios de test
acumulan 550 y 693 grupos y cada corrida añade ~20 y ~15; limpiarlos es destructivo. Con el ritmo de
hoy el golden más ajustado cae en unas 35 corridas. Cuatro caminos con su coste dentro del ticket.

El deploy del Worker sigue en pausa por decisión del 8-sep, no por acceso: `wrangler` está
autenticado y sus dos commits están en `2.1` desde el 3-sep.
