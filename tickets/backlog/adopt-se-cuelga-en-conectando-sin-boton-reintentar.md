---
id: adopt-se-cuelga-en-conectando-sin-boton-reintentar
status: backlog
priority: high
area: "modo-nube, onboarding, sync"
created: 2026-09-09
source: device-QA del owner en TestFlight build 13, 2026-09-09
---

# Entrar con Apple se queda clavado en «Conectando con tu cuenta…» y el botón de reintentar nunca aparece

## Qué pasa, en lenguaje de usuario

Elijo «Ya tengo una cuenta» → Apple. La app pasa a **«Conectando con tu cuenta…»** con el subtítulo
«Esto puede tardar unos minutos. Mantén Yala abierta», la barra de progreso vacía… y ahí se queda
**varios minutos**. No aparece ningún botón, ni error, ni forma de salir. La única salida es matar la
app.

Reportado por el owner el **2026-09-09** en TestFlight build 13, con captura: pantalla
`welcome_cloud_adopting`, barra en 0, sin ningún control visible.

## Lo que debería haber pasado

Existe una red para exactamente esto —`WelcomeAdoptAutoResume`
(`CloudWelcomeSignInFlow.swift:258-305`)— y su contrato es:

- poll de 1 s; **4 ticks** ociosos ⇒ auto-resume (`idleTicksBeforeResume = 4`)
- hasta **3** auto-intentos (`maxAutoAttempts = 3`)
- agotados sin avance ⇒ `showManualRetry = true` ⇒ la vista pinta el botón **«Reintentar»**
  (`WelcomeCloudSignInView.swift:481-488`, id `welcome_cloud_adopt_retry`)

⇒ En el peor caso, el botón debería estar en pantalla en **~12-15 segundos**. Tras varios minutos no
estaba.

## Hipótesis principal (NO confirmada — hace falta instrumentar)

El detector se dispara con `isAdopting && !isWorking` sostenido, y su propio docblock lo dice:
*«`isWorking == false` con fase `.adopting` significa que NADIE conduce»*. Es decir, **cubre el drive
APARCADO, no el drive COLGADO**. Si el `await` de dentro nunca vuelve, `isWorking` se queda `true`
para siempre, la racha ociosa se corta en cada tick (`next.idleTicks = 0`) y **el auto-resume no
dispara nunca** — ni el botón manual, que cuelga del mismo contador.

Sería un agujero estructural: la red protege del caso «se soltó el volante» y no del caso «alguien
agarra el volante y no lo suelta».

**Dato que lo hace verosímil, medido**: ninguna petición de `Yala/Services/CloudSync/` configura
`timeoutInterval`. En todo el cliente solo hay cuatro (`ProxyClientFactory.swift:27` = 20 s,
`AppUpdateService.swift:93` = 10 s, `ExchangeRateAPIService.swift:86,177` = 30/60 s) y ninguna es de
este camino. `URLSession.shared` trae 60 s de request pero **7 días** de recurso.

**Alternativa que hay que descartar antes**: que la fase no sea `.adopting` sino otra transicional, en
cuyo caso el poll ni mira. Se distingue por el `accessibilityIdentifier` de la pantalla.

## Qué haría falta

1. **Instrumentar antes de arreglar**: un log de `isAdopting` / `isWorking` / fase journaleada por tick
   contesta en una corrida cuál de las dos ramas es. Sin eso, cualquier arreglo es a ciegas.
2. Si es la hipótesis principal: la red necesita un **tope absoluto de tiempo en fase transicional**,
   independiente de quién crea que conduce — un drive que lleva N minutos en `.adopting` ofrece salida,
   conduzca alguien o no.
3. Y **timeout explícito** en las peticiones de `CloudSync/`: heredar los 7 días de recurso de
   `URLSession.shared` en el camino de entrada a la cuenta es demasiado.

## Salida para el usuario mientras tanto

Matar la app y reabrirla: `rekickIfParked()` corre en el arranque
(`AppBootstrapper.swift:1645-1647`) y retoma la máquina.

## Relacionados

- [[fresh-start-privado-no-ve-los-datos-de-icloud]] — mismo recorrido de Welcome, otra rama.
- El docblock de `WelcomeAdoptAutoResume` nació de `H-2026-07-17-5`, un caso en que la pantalla
  «quedaba clavada en "Conectando…"». Este reporte es el mismo síntoma con la red ya puesta ⇒ o la red
  no cubre este camino, o dejó de cubrirlo.
