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

## Qué debería pasar

La confirmación tiene que colgar de «¿hay datos en el destino que voy a estrenar?», no de «¿hay filas
en el store que tengo montado ahora mismo?». Dos vías, no excluyentes:

- **A — preguntar antes del relanzamiento** (lo que pide el owner). En el momento de elegir privado ya
  se sabe que se va a encender el espejo; ahí se consulta iCloud (la señal del KV-store que
  `RestoreOfferGate.hasReturningSignal` ya lee, y que **no se retiró** — la siguen leyendo
  `ContentView` y `WelcomeRestoreView`) y se confirma. Evita el reinicio en vano.
- **B — comprobar después del relanzamiento**, ya con el espejo montado y antes de dar el alta por
  buena. Más fiable (mira datos reales, no una señal), pero llega tarde: el usuario ya reinició.

**Decisión de producto pendiente**: A es lo que el owner describe y ahorra el viaje; B es lo que de
verdad ve los datos. Probablemente A como aviso y B como red.

## Cómo se comprueba

Cuenta con datos en iCloud, sesión cerrada, app recién instalada: «Empezar» → «Es mi primera vez en
Yala» → privado. Hoy no sale ninguna confirmación y, tras el reinicio, los datos vuelven.

**Control que distingue este bug de su vecino**: con datos **locales** presentes (sin reinstalar), el
alert sí sale. Lo que este ticket describe es el caso en que los datos están **solo en iCloud**.

## Relacionados

- [[welcome-start-fresh-wipes-before-ask]] — la otra mitad de la misma barrera; su verificación
  necesita datos **locales**, justo el caso contrario a éste.
- El aviso de montaje de `qa/guion-tanda.md`, Grupo C: reinstalar destruye la precondición.
