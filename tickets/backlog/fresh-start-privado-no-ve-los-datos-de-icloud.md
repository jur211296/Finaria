---
id: fresh-start-privado-no-ve-los-datos-de-icloud
status: backlog
priority: high
area: "onboarding, modo-nube, cloudkit"
created: 2026-09-09
source: device-QA del owner en TestFlight build 13, 2026-09-09
---

# «Empezar de cero» en privado no pregunta nada, y tras el reinicio te devuelve los datos que creías haber borrado

## Qué pasa, en lenguaje de usuario

Salgo de mi cuenta. Mis datos siguen en iCloud. Abro Yala, toco «Empezar» → «Es mi primera vez en
Yala» → elijo guardar en **mi iCloud privado**. **Nadie me pregunta nada**, y la app me pide reiniciar.
Al reabrir, entro en un alta completa como si fuera nueva… y mis datos viejos vuelven a bajar de
iCloud.

O sea: el reinicio fue en vano, y la barrera que tenía que avisarme —«ya hay datos ahí, ¿seguro?»— no
apareció en ningún momento.

**Reportado por el owner el 2026-09-09**, haciendo device-QA en TestFlight build 13, con estas
palabras: *«ahí es donde debería estar la barrera de: oye, ya hay datos en el repo privado, ¿estás
seguro de lo que quieres hacer? creo que ese es el momento correcto en el que debería saltar la
alerta»*.

## La causa, medida

No es que la comprobación falle: es que **no puede acertar en ese punto del flujo**.

1. **El primer arranque monta el store personal NEUTRO**, con `cloudKitDatabase: .none` *explícito*
   (`WelcomeMirrorRelaunchLogic.swift:12`). Sin espejo de CloudKit no baja nada, así que ese store
   está **vacío por construcción**.
2. **`checkHasExistingData()` cuenta filas de ese store local** y nada más — `modelContext.fetchCount`
   sobre `Account`, `Category`, `SplitGroup` y `TransactionItem` (`ContentView.swift:1118-1134`).
   Ninguna consulta a iCloud.
3. ⇒ En el momento del tap, `hasExistingData` es **false siempre**, y
   `startFreshPrivateOnboarding()` (`ContentView.swift:1663-1681`) toma la rama `else`: limpia
   preferencias residuales y entra al alta **sin preguntar**.
4. Elegir privado **sí** necesita el espejo, así que se interpone el relanzamiento
   («Ya casi está — reinicia Yala»). Al reabrir se monta **con** espejo… y los datos de iCloud bajan.

## Por qué se quedó sin barrera

El docblock de `startFreshPrivateOnboarding` se llama a sí mismo **«segunda barrera vs data
residual»** y justifica su alcance así:

> «el alert "Detectamos tu cuenta" del Hero cubre el caso iCloud-con-data, pero falla en (1) sim sin
> iCloud, (2) timeout del fetch, (3) CloudKit mirror sync que llega post-Hero»

**Esa primera barrera ya no existe.** Se retiró el 2026-08-11 por decisión del owner —«la reentrada es
decisión del usuario»— y el Hero hoy **no corre ninguna detección**: al tap «Empezar» va *siempre* al
chooser (`WelcomeHeroView.swift:5-16`). El literal «Detectamos tu cuenta» no está ni en el fichero de
traducciones; el único «Detectamos» que queda es el de la barrera local.

⇒ La barrera que quedaba viva se dimensionó para cubrir **sólo los huecos** de otra que se retiró un
mes después, y nadie revisó el docblock. Es el patrón de «el comentario describe la intención, no el
comportamiento», con el agravante de que aquí la premisa era **una dependencia entre dos barreras**.

## Y tras el relanzamiento tampoco valida (medido el 2026-09-09, segunda pasada del owner)

El owner comprobó el desenlace: **al reabrir, la app entra directa al onboarding de alta nueva, sin
ninguna validación**. No es un olvido, es el destino retenido:

```swift
if let pending = WelcomePendingDestinationStore.consume() {
    switch pending {
    case .privateOnboarding:
        showOnboarding = true      // ContentView.swift:1390-1393 — sin mirar datos
```

Su docblock lo justifica: *«el usuario YA eligió, y lo que este arranque tiene que hacer es honrar esa
elección en vez de volver a preguntar»*. Coherente — pero significa que **el flujo entero no tiene ni
un solo punto donde se compruebe si hay datos en iCloud**: ni antes del reinicio (store neutro vacío)
ni después (destino retenido que no pregunta).

## Qué debería pasar

La confirmación tiene que colgar de «¿hay datos en el destino que voy a estrenar?», no de «¿hay filas
en el store que tengo montado ahora mismo?». El owner propuso dos salidas; evaluadas contra el diseño:

- **A — preguntar antes del relanzamiento.** En el momento de elegir privado ya se sabe que se va a
  encender el espejo; ahí se consulta la señal del KV-store (`RestoreOfferGate.hasReturningSignal`,
  que **no se retiró**: la siguen leyendo `ContentView` y `WelcomeRestoreView`). Evita el reinicio en
  vano. Límite: es una **señal**, no los datos — puede faltar aunque haya datos.
- **B — validar en el `case .privateOnboarding`, antes de montar el alta.** Es el punto de enganche
  natural y **respeta** la decisión de honrar la elección: no vuelve a preguntar *qué* quería, sólo
  confirma *que borre*. ⚠️ **Tiene una carrera**: el espejo acaba de montarse en ese arranque y los
  datos de CloudKit pueden no haber bajado aún, así que una lectura inmediata puede dar cero igual.
  Es exactamente el hueco (3) que el docblock viejo ya nombraba, *«CloudKit mirror sync que llega
  post-Hero»*.
- **C — volver al Welcome al reabrir** (la otra idea del owner). Simple, pero **contradice** la
  decisión escrita en `ContentView.swift:1385-1389`: el destino retenido existe justo para no volver a
  preguntar. Descartable salvo que se revise esa decisión.

**Recomendación**: **A + B**. A ahorra el viaje y B es la red que de verdad ve los datos; ninguna de
las dos basta sola — A puede no tener señal, y B puede llegar antes que la sincronización. Y si se
implementa B, su espera tiene que ser por **llegada de datos**, no por temporizador.

**Decisión de producto pendiente del owner.**

## Cómo se comprueba

Cuenta con datos en iCloud, sesión cerrada, app recién instalada: «Empezar» → «Es mi primera vez en
Yala» → privado. Hoy no sale ninguna confirmación y, tras el reinicio, los datos vuelven.

**Control que distingue este bug de su vecino**: con datos **locales** presentes (sin reinstalar), el
alert sí sale. Lo que este ticket describe es el caso en que los datos están **solo en iCloud**.

## Relacionados

- [[welcome-start-fresh-wipes-before-ask]] — la otra mitad de la misma barrera; su verificación
  necesita datos **locales**, justo el caso contrario a éste.
- El aviso de montaje de `qa/guion-tanda.md`, Grupo C: reinstalar destruye la precondición.
