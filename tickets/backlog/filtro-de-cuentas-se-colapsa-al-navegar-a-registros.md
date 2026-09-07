---
id: filtro-de-cuentas-se-colapsa-al-navegar-a-registros
status: backlog
priority: low
area: statistics
created: 2026-09-07
updated: 2026-09-07
source: barrido del patrón al cerrar panel-colapsa-la-seleccion-de-cuentas-a-la-primera
---

# Al saltar de Estadísticas a Registros, el filtro de varias cuentas se queda en una

## Qué pasa

`Yala/App/ViewModels/StatisticsViewModel.swift` · `buildRecordsContext`

```swift
return RecordsFilterContext(
    accountID: selectedAccounts.first,
    categoryID: selectedCategories.first,
    subcategoryName: nil,
    need: selectedNeeds.first,
    ...
)
```

Tres colapsos de conjunto a `.first` en cuatro líneas. `RecordsFilterContext` solo admite un
`accountID`, un `categoryID` y un `need`, así que al navegar de Estadísticas a Registros con dos
cuentas filtradas llegas filtrado por **una**, y —igual que en el bug del Panel— cuál no es estable:
`Set.first` no lo garantiza.

Es el mismo patrón que cerró `panel-colapsa-la-seleccion-de-cuentas-a-la-primera`, en el camino de
navegación en vez de en el cálculo. Salió del barrido de «todas las instancias del patrón» al cerrar
aquel.

## Qué NO es

No es el mismo bug que el del Panel: allí un número salía mal. Aquí el número está bien, lo que se
pierde es el filtro al cambiar de pantalla. Por eso va como `low`: molesta, no miente.

## Lo que hay que mirar antes

`RecordsFilterContext` (`Yala/App/Models/RecordsModels.swift`) tiene campos escalares. Respetar el
conjunto obliga a cambiarlo a `Set` y a tocar a sus consumidores, o a aceptar que la navegación
lleva un filtro más laxo del que traía. **Medir cuántos consumidores tiene antes de decidir el
alcance** — solo se construye en un sitio, pero se lee en varios.

## Sin confirmar: el gemelo en categorías y needs del Panel

`PanelViewModel` expone `selectedCategoryID` (`selectedCategoryIDs.first`) y `selectedNeed`
(`selectedNeeds.first`) con la misma forma que tenía `selectedAccountID`.

**No está confirmado que sean alcanzables**: `SessionState.toggleCategoryFilter` es single-select y
no se encontró un `insert` sin `removeAll` para categorías en `RecordsFiltersView`, al contrario que
con las cuentas. Antes de tratarlo como bug hay que **buscar todos los escritores** de
`selectedCategoryIDs` y `selectedNeeds` y ver si alguno mete dos. Si ninguno lo hace, no hay bug —
solo un accessor con una forma peligrosa, y la regla `.claude/rules/session-filters.md` ya avisa.

## Acceptance Criteria

- [ ] Medida la alcanzabilidad real del multi-select en categorías y needs.
- [ ] Con dos cuentas filtradas, saltar de Estadísticas a Registros conserva las dos (o se decide y
      documenta que no).
- [ ] Unit del contexto de navegación con conjunto de dos.
