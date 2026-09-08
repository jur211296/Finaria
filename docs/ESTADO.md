---
updated: 2026-09-08
tags: [now, punto-de-retomada]
---

# NOW — 2026-09-08 (Lima)

**Rama** `2.1` · HEAD `05dbba27` — Merge #102: un gasto dictado al chat resta del saldo
TestFlight build **12** (CPV 12). **Subida Yala (TF/store) = solo Mini.**

## Esta sesión

**Un gasto dictado al chat ya resta del saldo en vez de sumarlo** (PR #102). El monto se guardaba
sin signo en las **dos** columnas, así que el gasto entraba en el resto de la app como un reembolso:
subía la curva del Panel, **restaba** de «Gastos del mes», y descuadraba Informes, Insights, widgets
y el mapa diario, donde además borraba el día. Cuatro líneas de arreglo, ocho superficies.

**Duró cuatro meses y medio porque era asimétrico:** «Guardar» salía mal y «Editar → Guardar» salía
bien, porque esa vía pasa por el formulario, que sí firma. Quien lo probara editando no veía nada.

**La premisa del ticket era falsa** —«las listas cuadran, solo falla el saldo»— y la copié a tres
sitios antes de medirla. Eso y una aserción mía que no podía ponerse roja las cazó la review
adversarial; las dos están en la memoria de Frank.

## Abiertos

1. **Decisión de Jürgen — `chat-rows-with-unsigned-amount-have-no-repair-path` (high).** Las filas ya
   guardadas siguen rotas y nada las cura. No se distinguen de un reembolso legítimo:
   `TransactionItem` no tiene campo de origen, y «categoría de gasto con monto positivo» es una forma
   que la app admite a propósito. Tres salidas —no migrar, migrar a ciegas rompiendo datos buenos, o
   preguntárselo al usuario— y ninguna obvia. El ticket las deja escritas.
2. **`goldens-de-staging-solo-pasan-a-trozos`** — 14-15/25 en tres corridas. Todos los fallos son
   timeouts, **cero aserciones**. Cuatro hipótesis caídas. La siguiente medición está escrita en el
   ticket: instrumentar `pull()` y contar viajes. Sospechoso: los 677 grupos acumulados de `jwtA`.
3. **Device-QA** acumulado: dueño atrapado, recordatorio y «≈» (éste **no es simulable**), más el
   signo del chat de hoy, que **sí lo es** — dictar un gasto y mirar el saldo.
4. **DMARC el 15-sep** · **cobertura de UI el 22-sep**. Esperan al calendario, no a nadie.

## Siguiente

El device-QA del chat, que es barato y cierra el ticket. Después, el rojo de los goldens.

## Bloqueo

El punto 1 espera decisión suya. El deploy del Worker sigue en pausa por decisión del 8-sep, no por
acceso: `wrangler` está autenticado y sus dos commits están en `2.1` desde el 3-sep.
