---
updated: 2026-09-08
tags: [now, punto-de-retomada]
---

# NOW — 2026-09-08 (Lima)

**Rama** `2.1` · HEAD `00233296` — Merge #103: el corpus viejo del chat ya se cura solo
TestFlight build **12** (CPV 12). **Subida Yala (TF/store) = solo Mini.**

## Esta sesión

**Los gastos que el chat guardó sin signo ya se corrigen solos** (PR #103). El PR #102 arregló la
ruta hacia delante; estas filas —cuatro meses y medio— quedaban rotas para siempre, porque ninguno
de los cinco mecanismos que tocan esas columnas corrige un signo. Un barrido one-shot las voltea en
el primer arranque.

**Jürgen decidió dos veces.** Primero migrar a ciegas acotando por fecha, aceptando que los
reembolsos legítimos de la ventana también se volteen. Después, al llevarle la medición de que el
criterio alcanzaba además a lo importado por CSV —más ancho de lo que había aceptado—: **acotar**.

**La señal que lo resolvió, y que el ticket daba por inexistente:** una fila del CSV es
indistinguible campo a campo de una del chat, pero **nace a la vez que otras** — el importador crea
el lote sin `save()` intermedio y el chat exige un toque por tarjeta. El propio importador ya se
reconoce así para emparejar transferencias.

Tres verdes míos eran falsos y dos justificaciones del diseño estaban medidas al revés; el patrón
—una condición duplicada deja el criterio sin probar— está en la memoria de Frank.

## Abiertos

1. **`goldens-de-staging-solo-pasan-a-trozos`** — 14-15/25 en tres corridas. Todos los fallos son
   timeouts, **cero aserciones**. Cuatro hipótesis caídas. La siguiente medición está escrita en el
   ticket: instrumentar `pull()` y contar viajes. Sospechoso: los 677 grupos acumulados de `jwtA`.
2. **Device-QA** acumulado: dueño atrapado, recordatorio y «≈» (éste **no es simulable**), el signo
   del chat de #102 y el barrido de hoy — los dos **sí** lo son: dictar un gasto y mirar el saldo
   antes y después del primer arranque. El barrido imprime en DEBUG cuántas filas curó, que es el
   número que nunca se pudo medir desde el repo.
3. **DMARC el 15-sep** · **cobertura de UI el 22-sep**. Esperan al calendario, no a nadie.

## Siguiente

El device-QA, que ya acumula cuatro tickets y cierra dos de golpe. Después, el rojo de los goldens.

## Bloqueo

Ninguno pendiente de decisión. El deploy del Worker sigue en pausa por decisión del 8-sep, no por
acceso: `wrangler` está autenticado y sus dos commits están en `2.1` desde el 3-sep.
