---
id: reentry-killswitch-closes-both-doors
status: backlog
created: 2026-09-05
updated: 2026-09-06
source: tickets/qa/reentry-counts-as-fresh-install.md (§4, §5 y §6)
---


# Con el kill-switch, quien vuelve se queda sin las DOS puertas

Sale de `reentry-counts-as-fresh-install`, cuyas piezas 1-3 quedaron cerradas el 2026-09-05. Lo que
sigue aquí es lo que **no** se tocó: una pieza que necesita decisión de producto y dos que son diseño y
comentario, no fix. Se separan para que el ticket padre pueda irse a QA sin arrastrarlas.

**Las coordenadas de abajo vienen del ticket padre y NO se re-midieron en esta sesión.** Greppea antes de
abrir una línea citada.

## 1 · El residual escrito solo menciona una de las dos puertas

El comentario en el código dice que «un usuario nube que REINSTALA bajo el kill no ve la card → no
re-entra hasta re-encendido». Lo que el padre midió es que la fila **«Dónde viven tus datos»** de
Ajustes —la segunda puerta, la de la adopción por marcador— **también desaparece**: su gate es
`remoteEnabled || isEngaged` (`StorageRowGateLogic`) y una reinstalación no puede ser engaged. El faro
además deja de encaminar, porque `cloudEntryAvailable` se deriva de la card que se fue
(`WelcomeAccountChoiceLogic`).

Para un born-cloud, la única card que queda («Restaurar desde iCloud») termina en **«No encontramos tus
datos»** con sus datos intactos en el backend.

**Por qué no entró:** tocar el gate del kill-switch es una decisión de producto de Jürgen —el encargo del
5-sep lo excluía explícitamente— y lo barato mientras tanto es que el residual del código deje de
describir mal lo que hace. Lo mínimo aquí es corregir ese comentario; lo completo es decidir si la
segunda puerta debe seguir viva bajo el kill.

## 2 · El relanzamiento cero llegó al alta y no a la re-entrada

En un móvil recién instalado los dos caminos montan el mismo store neutro. El alta born-cloud pregunta
al testigo de mount y termina en «¡Tu cuenta está lista!» arrancando el motor **en sesión**; el adopt no
pregunta nada y cae en la terminal «Ya casi está — reinicia Yala».

Medido en el padre: `startAdoptWithExistingSession` **no** llama a `startRuntimeIfStable()`, así que hoy
el relanzamiento es lo único que arranca el motor — la pantalla es honesta en el efecto, pero el
comentario de `CloudWelcomeSignInFlow` («el relaunch ya se resolvió en otro proceso — terminal
equivalente») describe mal este caso: aquí ningún proceso resolvió nada.

**Es una oportunidad de producto, no un defecto**, y por eso no se implementó: si el motor arrancara en
sesión como en el alta, la re-entrada podría dejar de pagar su relanzamiento. Necesita decisión antes que
código.

## 3 · Un belt que se justifica con una premisa falsa

El paso 4 de `runAdoptFlow` acepta `markerCount == 0` con un breadcrumb porque «la ruta ya validó el
marcador al abrir la pantalla» (`MigrationWorkExecutor`). Cierto para la puerta de Ajustes; **falso para
la puerta del Welcome**, que nunca mira ningún marcador. En un móvil recién instalado el marcador es
*imposible* (vive en el mirror de CloudKit y el proceso montó sin mirror) ⇒ el breadcrumb «marker absent»
es el caso **normal** de este recorrido, no una anomalía a investigar.

Es un docblock, y la prioridad del padre decía «con el siguiente cambio que toque esos ficheros». Las
piezas 2 y 3 no tocaron `MigrationWorkExecutor.swift`, así que sigue esperando a quien lo haga.

## Decisión Jürgen (2026-09-06)

Las piezas 1 y 2 pedían decisión; la 3 es un docblock y no se le preguntó.

**Pieza 1 — bajo el kill, las DOS puertas cerradas es lo deseado, y se arregla el mensaje.** Elegida
entre tres: (a) las dos cerradas + corregir comentario + corregir el mensaje del Welcome, (b) las dos
cerradas y solo el comentario, (c) mantener viva la puerta de Ajustes bajo el kill. Eligió (a). Motivo,
tal como se le puso delante y ratificó: el kill significa **nube en pausa para todos, también para
volver**; lo que no es aceptable es que un nacido-en-nube con sus datos intactos lea «No encontramos tus
datos». Descartó (c): tocar el gate del kill (`StorageRowGateLogic`) es tocar el freno de emergencia.

Lo que implica: el residual del código pasa a decir que bajo el kill se cierran **las dos** puertas
(card del Welcome y fila «Dónde viven tus datos»), y el camino «Restaurar desde iCloud» bajo el kill
termina en un mensaje que dice que la nube está en pausa, no que los datos no existen. Copy nuevo, 16
`.lproj`.

**Pieza 2 — el motor arranca en sesión también en la re-entrada.** Elegida entre dos: arrancar el
motor en sesión como hace el alta, o dejar el relanzamiento y corregir el comentario. Eligió la primera.
Motivo, tal como se le puso delante y ratificó: es la versión robusta y la coherente con el alta —dos
caminos que montan el mismo store neutro no deberían terminar en pantallas distintas—. Lo que implica:
`startAdoptWithExistingSession` llama a `startRuntimeIfStable()` (o su equivalente en el flujo) y la
re-entrada termina en «¡Tu cuenta está lista!» en vez de «Ya casi está — reinicia Yala»; el comentario
de `CloudWelcomeSignInFlow` que hablaba de «terminal equivalente» se reescribe.

**Pieza 3** sigue como estaba: docblock de `MigrationWorkExecutor`, con el siguiente cambio que toque el
fichero.

## Criterio de hecho (AC)

- [ ] Con el kill encendido y una instalación limpia, ni la card del Welcome ni la fila de Ajustes
      ofrecen la nube (ya pasa hoy), y el comentario del código lo dice de las **dos** puertas.
- [ ] Con el kill encendido, un nacido-en-nube que pasa por «Restaurar desde iCloud» lee que la nube
      está en pausa, **no** «No encontramos tus datos». Copy propio, 16 `.lproj`.
- [ ] La re-entrada por la puerta del Welcome en un móvil recién instalado arranca el motor en sesión
      y termina en la misma pantalla de «lista» que el alta; **sin** «reinicia Yala».
- [ ] La re-entrada por la puerta de Ajustes se comporta igual (mismo `runAdoptFlow`); comprobar que
      arrancar el motor en sesión no rompe el caso con marcador presente.
- [ ] Device-QA: móvil limpio (borrar app) × {kill apagado, kill encendido} × {alta, re-entrada}.
      **Pendiente: es lo que falta tras implementar**, y el kill se conmuta desde el backend.
- Coordenadas: las de arriba vienen del ticket padre y **no se re-midieron** aquí. Greppear antes.
- Toca el arranque del motor de sync ⇒ **review adversarial** antes del gate.

## Relacionados

- [[reentry-counts-as-fresh-install]] — el padre, en `qa/` desde el 2026-09-05
