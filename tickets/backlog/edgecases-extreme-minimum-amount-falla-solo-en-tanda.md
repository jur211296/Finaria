---
id: edgecases-extreme-minimum-amount-falla-solo-en-tanda
status: backlog
priority: medium
area: testing
created: 2026-09-07
updated: 2026-09-07
source: gate de panel-colapsa-la-seleccion-de-cuentas-a-la-primera
---

# `test_extremeMinimumAmountSaves` falla en tanda y pasa en aislado

## Qué pasa

`YalaUITests/EdgeCasesUITests.test_extremeMinimumAmountSaves()` falla con:

```
XCUIApplication+Yala.swift:208: XCTAssertTrue failed - No apareció la pantalla de éxito
de la transacción (transaction_success_accept) — el guardado no completó.
```

Solo cuando corre **junto a otras suites de UI**. En aislado pasa.

## Medido el 2026-09-07 — dueño: Frank

No es una impresión: es la tabla que zanjó si el rojo era del cambio en curso o del árbol.

| Árbol | Comando | Resultado |
|---|---|---|
| `encargo/…panel-colapsa…` | las 5 suites juntas | **FALLA** — 11 tests, 1 fallo |
| **`HEAD` limpio (`ad39a13d`)** | **las 5 suites juntas** | **FALLA — 11 tests, 1 fallo, el MISMO test** |
| `encargo/…panel-colapsa…` | `EdgeCasesUITests` solo, ×2 | PASA — 2 tests, 0 fallos |
| `HEAD` limpio | `EdgeCasesUITests` solo | PASA — 2 tests, 0 fallos |

Las 5 suites: `EdgeCasesUITests`, `PanelDashboardUITests`, `ProConversionUpsellsUITests`,
`StatisticsNavigationUITests`, `WelcomeFreshStartAlertUITests` (scheme `Yala Dev`, iPhone 17 Pro).

**El árbol base falla igual ⇒ el rojo no lo introduce ningún cambio de esa rama.** Y como en aislado
pasa en los dos árboles, tampoco es un rojo permanente: es la **tanda** lo que lo rompe.

Disco durante las corridas: 11-14 GB libres. Por debajo del umbral de 25 GB, así que **no se puede
descartar la vía del disco** — CoreSimulator falla con errores que no lo mencionan. Es la primera
hipótesis a comprobar, y es barata: repetir la tanda con >25 GB libres.

## Por qué importa

`EdgeCasesUITests` corre en el paso 3 de `/gate` para cualquier cambio que toque el Panel o
Estadísticas (sus `codeGlobs` son amplios). Un rojo que aparece solo en tanda convierte ese paso en
ruido: la próxima sesión verá el mismo fallo y tendrá que repetir estas cuatro corridas para
descartarlo. Ese es el coste real, y se paga cada vez.

## Qué mirar

1. **Disco por encima de 25 GB** y repetir la tanda. Si desaparece, era el entorno y se cierra.
2. Si persiste: estado compartido entre suites. `test_extremeMinimumAmountSaves` guarda una
   transacción; lo que corre antes puede dejar la app en una pantalla o con datos que impiden que
   aparezca `transaction_success_accept`. Mirar el orden de ejecución y qué deja atrás la suite
   previa.
3. Comprobar si el fallo **se muda de test** al cambiar el orden de las suites: si se muda, es
   contaminación o timing, no este test.

## Acceptance Criteria

- [ ] Reproducido o descartado con >25 GB de disco.
- [ ] Identificado si es contaminación entre suites o timing.
- [ ] La tanda de las 5 suites pasa en verde de forma repetible (≥3 corridas).
