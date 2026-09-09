---
name: seam-cuenta-divisa-ausente
description: PR #114 — el seam `-uitest-seed-foreign-account <ISO>` que desbloquea la familia FX en simulador; qué tickets salen enteros, cuáles a medias y qué seam falta para los dos que siguen parados.
metadata:
  type: project
---

**Desde el 2026-09-09 se puede sembrar una cuenta en una divisa fuera de la fila de tasas sin tocar
la UI** (PR #114, `-uitest-seed-foreign-account <ISO>`, aditivo al perfil y apagado por defecto).

**Why:** era la palanca con mejor relación coste/desbloqueo del board — siete tickets de FX
esperaban ese único estado de partida y ninguno necesitaba teléfono. El camino por UI está cerrado
de verdad y conviene no volver a intentarlo: el selector de Moneda es un `NavigationLink` y no
responde a los taps sintéticos (medido con cuatro técnicas, y el `NavigationLink` hermano tampoco
abre ⇒ va con el patrón, no es un bug de la app).

**How to apply:**

- **Lo que el seam da, y lo que no.** Da una divisa ausente de la fila ⇒ `.staticFallback` ⇒ filas
  marcadas provisionales por el camino de producción. **No** da: dos patas con coberturas distintas
  (lo pide `bridge-de-grupos-pierde-la-marca-de-sus-patas`) ni una fila envenenada con
  `exchangeRate = 1.0` (lo pide `chat-rows-sealed-before-the-fix-have-no-repair-path`). Esos dos
  siguen parados y **lo que les falta es seed, no teléfono**: son los siguientes candidatos baratos.
- **La salida 3 quedó sin hacer a propósito** (`-uitest-preferred-currency <ISO>`): el AC no la pedía
  y ejercita `CurrencyChangeService`, otro objeto. La necesita el AC nº3 de
  `fx-partial-rate-rows-silent-1to1`; está anotada allí.
- **Al verificar con este seam, acota el período.** Con «Todo el tiempo» NO marca (0,36 %, bajo el
  umbral del 5 %) y eso es correcto, no un fallo. Está escrito en el ticket porque es justo el falso
  negativo que alguien va a reportar.
- Tres tickets siguen sin salir del simulador por causas ajenas al montaje: dos piden **red** y uno
  el **LLM real**.

**Lo que aprendí del corpus, y que vale para cualquier fixture futuro de FX:** el seed normal
escribe `exchangeRate` a mano y deja `isExchangeRateProvisional` en su default `false`, así que
**cualquier aserción sobre ese flag sobre el corpus sembrado es vacua por construcción**. Un fixture
que quiera probar la marca tiene que pasar por `recalculatePreferredCurrency`, o solo prueba que sé
escribir constantes. Ver [[la-asercion-que-no-puede-fallar]].

**Y una cifra que corregí midiendo, porque la de partida era falsa:** el ticket decía cuatro tickets
bloqueados y el `docs/ESTADO.md` decía cinco. **Son siete** los que esperan el montaje, y de los
cuatro que nombraba, dos pedían además otra cosa y uno no declaraba bloqueo alguno.
Ver [[la-premisa-del-encargo-tambien-se-mide]].
