---
id: preferred-currency-has-three-different-defaults
status: backlog
priority: medium
area: "currency, preferences"
created: 2026-09-09
source: hallazgo de camino de `qa-no-puede-crear-cuenta-en-otra-divisa` (2026-09-09)
---

# Cuatro sitios leen la divisa preferida y, si falta, se responden tres cosas distintas

## Qué pasa

`defaultCurrencyCode` es una key de `UserDefaults`. La escriben el onboarding y los ajustes, y la
**borra** «Empiezo de cero» (`DataWipeService.swift:566`). Cuando no está —usuario recién barrido,
o cualquier arranque que salte el onboarding— cada lector se inventa un default distinto:

| dónde | qué devuelve si la key falta |
|---|---|
| `Yala/Utils/CurrencyUtils.swift:829` (`CurrencyDefaults.currentPreferred`) | **la región del dispositivo** (`detectCurrencyFromRegion()`) |
| `Yala/App/Services/AppPreferences.swift:81` | **`.pen`** |
| `Yala/Services/ExchangeRateService.swift:693` | **`"PEN"`** |
| `Yala/Services/WidgetDataCache.swift:372` | **`"USD"`** |

Los cuatro medidos el 2026-09-09 en el árbol de `encargo/2026-09-09-qa-no-puede-crear-cuenta-en-otra-divisa`.

La línea del widget es la más llamativa por lo que tiene justo encima:

```swift
// Get preferred currency from user settings (single source of truth)
let preferredCurrency = UserDefaults.standard.string(forKey: CurrencyDefaults.preferredCurrencyKey) ?? "USD"
```

El comentario dice «single source of truth» y la línea es la que más se aparta de las otras tres.

Hay una quinta dimensión, y conviene mirarla en el mismo pase: dos de los cuatro leen
`UserDefaults.standard` y dos leen `SessionDefaults.current`. Bajo sesión secundaria esos dominios
divergen a propósito (`SessionDefaults.swift`), así que la pregunta «¿de quién es esta divisa?»
también tiene hoy dos respuestas.

## Por qué importa

`CurrencyDefaults.currentPreferred` es lo que usa `TransactionItem.recalculatePreferredCurrency`
para decidir la divisa DESTINO de una conversión que se **persiste en disco** y se emite al canal
nube. Si ese lector dice USD (región `US`) mientras `AppPreferences` pinta PEN, la app enseña un
total en soles construido con importes convertidos a dólares. No es una preferencia de formato: es
el número.

El caso de usuario que lo dispara está escrito en el propio wipe — «Empiezo de cero» borra la key y
deja la app leyéndola de cuatro sitios que no coinciden.

## Lo que NO es

No se ha observado el síntoma en pantalla. Esto es un hallazgo **estructural, medido en el código**,
no un bug reproducido: en la Mac del owner el simulador es `es_PE`, así que
`detectCurrencyFromRegion()` devuelve PEN y los cuatro defaults coinciden por casualidad del
entorno. **Esa coincidencia es justo lo que lo hace invisible aquí y visible fuera.**

## Cómo se sabe que está bien

- Un solo sitio decide el default de la divisa preferida cuando la key falta, y los otros tres lo
  llaman. Un source-scan que impida que vuelva a aparecer un `?? "PEN"` o un `?? "USD"` suelto,
  al estilo del que ya protege el centinela del seed (`UITestSeamPersistenceIsolationTests`).
- Un test que fije la región a una NO peruana y compruebe que los cuatro lectores coinciden.
  `detectCurrencyFromRegion(regionCode:)` ya es inyectable, así que no hace falta tocar el entorno.
- Decidir cuál es el default correcto es parte del ticket, y no es obvio: la región es más útil para
  un usuario nuevo, y un literal es más predecible para el reparador de tasas.
