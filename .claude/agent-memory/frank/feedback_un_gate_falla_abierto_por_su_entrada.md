---
name: un-gate-falla-abierto-por-su-entrada
description: Un guard que decide sobre una LISTA se abre solo cuando el fetch de esa lista falla — vacío y «no pude saberlo» se leen igual. Y el snapshot que lee se congela mientras haces `await`.
metadata:
  type: feedback
---

**Cuando escribas un guard que decide mirando una colección, pregúntate qué hace si esa colección
llega vacía POR ERROR. Casi siempre: se abre.**

**Why:** el 2026-09-09 mi gate del cambio de divisa clasificaba las filas de una cuenta. El `catch`
de `loadTransactions` dejaba `allTransactions = []`, y una lista vacía se lee igual que «esta cuenta
no tiene movimientos» → veredicto «libre» → la divisa cambiaba sin convertir nada, que era el bug
entero entrando por la puerta de atrás. El fallo del fetch **desarmaba el guard que existía para
ese fallo**.

**How to apply:**

- **Registra el fallo, no solo el resultado.** Un `didFailToLoad` junto a la lista, y el guard lo
  trata como bloqueo. «No hay» y «no lo sé» llevan a decisiones opuestas.
- **Y el snapshot se congela.** El mismo día, la otra mitad: `allTransactions` se cargaba al abrir
  el formulario, y entre medias había un `await` que hacía red. En esa ventana el sync puede
  escribir una fila nueva — que se quedaba sin convertir **y el re-gate no la veía**, porque releía
  el mismo array. ⇒ **refetch DESPUÉS del `await`**, justo antes de actuar. `CurrencyChangeService`
  ya lo hacía así y fue el precedente que lo delató.
- **Para fijarlo con un test hace falta un seam**, porque un `ModelContext` in-memory sano no lanza:
  un `_testSimulate…Failure()` bajo `#if DEBUG`. Sin él, el guard que impide el peor caso es
  precisamente el que ninguna aserción puede tocar — la familia de
  [[la-asercion-que-no-puede-fallar]].

Las dos mitades las cazó la **tercera** lente adversarial, no las dos primeras: es
[[lentes-adversariales-se-contradicen]] por el lado bueno — cada lente ve su eje y ninguna ve el de
al lado.
