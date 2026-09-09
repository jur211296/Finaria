# Guion de la tanda de QA

> **Qué es esto.** Los tickets de `tickets/qa/` no se drenan de uno en uno: se acumulan y se hacen
> juntos (decisión del owner, 2026-09-03). Este guion los agrupa **por montaje**, que es donde está el
> ahorro — siete de ellos necesitan dos teléfonos, y montar eso una vez en lugar de siete es la mitad
> del trabajo de la tanda.
>
> **Actualizado: 2026-09-08 · 23 tickets con montaje asignado.** Al mover algo a `qa/` o sacarlo de ahí,
> actualiza también este guion; si no, en dos semanas manda a montar cosas que ya no hacen falta.
>
> ⚠️ **Re-medido el 2026-09-09: en `tickets/qa/` hay 52 tickets `.md` y aquí se nombran 21. Quedan 31
> sin montaje asignado**, no 17 — la cifra vieja es de cuando la cola tenía 39. Una tanda guiada solo
> por este fichero los deja fuera sin avisar. Repartirlos es trabajo aparte →
> [[qa-guion-tanda-no-cubre-17-tickets]].
>
> 📍 **El cluster de Grupos tiene guion propio y ejecutable: [`guion-grupos-dos-telefonos.md`](guion-grupos-dos-telefonos.md).**
> Cubre invitación → entrada → aprobación → gasto → salida en una sola pasada, y **clasifica qué
> necesita de verdad dos teléfonos**: de los 16 tickets del cluster, solo 3 son irreductibles a APNs
> real. El resto pide dos *cuentas* (dos simuladores contra staging bastan), un solo dispositivo, o
> nada más que un simulador.
>
> `qa` NO significa «terminado»: significa que el código está hecho y verificado hasta donde el
> simulador alcanza, y que falta la comprobación en aparato real.

## Orden recomendado

Por montaje, de menor a mayor coste de preparación. **Los grupos C y D no necesitan nada especial y se
pueden hacer en cualquier rato**; los grupos A y B piden preparar aparatos, así que conviene juntarlos
en una sesión sola.

---

## Grupo A · Dos teléfonos con TestFlight (8 tickets)

**Montaje único para los ocho**: dos aparatos con TestFlight, dos cuentas distintas (A y B), la misma
build. App Attest está en `enforce`, así que **nada de esto sale en simulador ni en build de Xcode** —
ése es el motivo de que lleven aquí y no se hayan podido cerrar antes.

**Prepara antes de empezar:** `wrangler tail --env production` corriendo en una terminal. Es la señal
más barata para los tres de notificaciones, y sin ella un fallo silencioso del servidor no se distingue
de uno de entrega.

| Ticket | Qué comprobar |
|---|---|
| `aviso-de-nuevo-miembro-no-llega-hasta-abrir-la-app` | B pide entrar al grupo de A → **a A le llega el banner con la app cerrada** |
| `groups-expense-notif-only-on-foreground` | A crea un gasto → **a B le llega con la app en segundo plano**, y también con la app matada |
| `invite-backend-stale-config` | El enlace funciona aunque el aparato tenga la configuración vieja cacheada |
| `scheduled-payments-notif-dedup` | Varios pagos el mismo día → **una sola** notificación, a la hora configurada |
| `siri-intent-dual-container` | El atajo de Siri escribe donde debe |
| `storekit-appgroup-siri-pro-gate` | El gate Pro del atajo — **sus pasos 1 y 2 ya están corridos**, mira el ticket antes de repetirlos |
| `applepay-shortcut-warm-launch-empty-data` | Tras la automatización de Apple Pay, la app NO queda vacía |
| `groups-archived-group-rejects-join` | A **archiva** el grupo → B tapea el enlace y ve «<grupo> fue archivado», **no** «Enlace no válido». Luego A **desarchiva** → B vuelve a tapear y ahora **sí** entra como pendiente |

**Dos avisos medidos que ahorran una tarde:**

- Si el banner no llega, **antes de sospechar del servidor** mira `Ajustes → Yala → Notificaciones` en
  el receptor: el único ticket cerrado del repo sobre esto era el permiso apagado, y APNs devuelve 200
  igualmente. No hay forma de distinguirlo desde el servidor.
- **`PUSH_ROLE_JWT` está configurado en producción** (verificado el 2026-09-03). Si el fan-out no sale,
  no es por eso — esa hipótesis ya está descartada en el ticket.
- El rate-limit de avisos de grupo es de **5 minutos por grupo**, y persiste entre arranques: dos
  pruebas seguidas parecerán «no llegó» cuando lo que hubo es un colapso por diseño. Espera entre
  intentos y anota las horas.

---

## Grupo B · Móvil prestado (5 tickets)

**Montaje único**: un aparato, dos cuentas — la del dueño y una visita que entra con la suya.
`SECONDARY_SESSION` está al **0 %** en producción, así que hay que abrir el recorrido a mano.

| Ticket | Qué comprobar |
|---|---|
| `secondary-groups-off-wipes-owner` | La visita **no puede borrar los grupos del dueño**. Recién arreglado; el ticket trae receta de repro |
| `prefs-domain-per-secondary-session` | Los ajustes de la visita no pisan los del dueño |
| `widget-snapshot-visitor-overwrites-owner` | El widget no se queda con los números de la visita |
| `groups-consent-door-spec` | El consent de Grupos viaja con la cuenta, no con el aparato |
| `secondary-guest-exit-lock-and-outbox` | La visita **se puede ir**: con red degradada y un gasto de grupo sin subir, el aviso ofrece «Esperar» y «Salir igualmente» en vez de culpar a la conexión. **Precondición**: degradar la red DESPUÉS de crear el gasto y ANTES de tocar «Cerrar sesión» |

---

## Grupo C · Simulador · el recorrido de bienvenida (3 tickets)

**Un solo recorrido cubre los tres.** Abre la app con datos previos en el teléfono y recorre
«Empezar» → «Es mi primera vez», probando cancelar en cada punto.

> ⚠️ **La precondición no es «tener datos»: es tener datos LOCALES en el dispositivo en el instante
> del tap.** Medido en device el 2026-09-09, y costó el intento: el alert
> «Detectamos datos previos en tu dispositivo. ¿Borrar todo para empezar como nuevo?» lo gobierna
> `hasExistingData` en `ContentView.startFreshPrivateOnboarding()` — si es `false`, **no hay alert**
> y se pasa directo al alta. **Reinstalar la app destruye ese estado**: la base local queda vacía y
> CloudKit aún no ha bajado nada, así que los tres tickets se vuelven inobservables justo cuando
> creías estar montándolos. Y no basta con esperar: hay que confirmar que los datos ya están
> **abajo, en la app**, antes de tocar «Es mi primera vez».
>
> **El flujo real tiene tres pantallas, no una** — no se puede saltar al botón final:
> **Hero** («Tus finanzas personales, sin esfuerzo» → «Empezar») → **chooser** («¡Hola! ¿Qué quieres
> hacer en Yala?») → y ahí se bifurca:
> - **«Es mi primera vez en Yala»** → alert `welcome.freshStart.*` («Empezar desde cero» / «Borrar
>   todo y continuar»). Es la entrada de `welcome-start-fresh-wipes-before-ask`.
> - **«Ya tengo una cuenta»** → `WelcomeRestoreView`, que busca en iCloud y **tiene su propio botón**
>   «Empezar desde cero» (`welcome.restore.startFresh`). Otro camino y otro ticket.
>
> Son dos entradas distintas al mismo borrado y se confunden con facilidad: los literales se parecen
> y viven en dominios de traducción distintos.
>
> **Camino feliz medido en device (build 13):** sin datos locales, «Es mi primera vez» **no** pregunta
> —correcto, no hay nada que borrar—, limpia las preferencias residuales del KV-Store y pide
> **«Ya casi está — reinicia Yala»**; al reabrir entra en el alta completa. Eso **no verifica ninguno
> de los tres tickets**: sólo confirma que la rama sin datos se comporta.

| Ticket | Qué comprobar |
|---|---|
| `welcome-fresh-start-alert-leaves-blank-screen` | Cancelar el alert **devuelve al selector**, no a una pantalla en blanco |
| `welcome-start-fresh-wipes-before-ask` | No se borra nada antes de preguntar, y si el borrado falla te enteras |
| `welcome-copy-blames-owner` | El texto no acusa a la dueña de traer datos ajenos. **Su residual necesita SIWA real**, así que esa parte se va al grupo A |

---

## Grupo D · Simulador con datos (7 tickets)

Sin montaje especial. Necesitan una cuenta con **cuentas en dos monedas** y un histórico de varios
meses, así que siembra primero.

| Ticket | Qué comprobar |
|---|---|
| `fx-partial-rate-rows-silent-1to1` | Los tres criterios del ticket. **Necesita red y un histórico real de tasas**: es el más exigente de este grupo |
| `undercount-dias-intervalos-cerrados` | En «mes pasado», el promedio diario y el gasto por día de la semana cuadran con los días reales del mes |
| `registros-calendario-cuenta-gastos-por-signo` | El calendario de Registros cuadra con el resto de la app |
| `cloud-fx-rates-blob-two-faces` | Las tasas sobreviven al viaje por la nube |
| `prefs-synced-keys-upload-not-download` | Los ajustes que suben, vuelven |
| `update-banner-appstore-criteria` | El banner de actualización, con sus criterios |
| `chat-rows-sealed-before-the-fix-have-no-repair-path` | Una fila sembrada con tasa `1,0000` en divisa ajena y monto convertido real: al arrancar, el detalle enseña la tasa verdadera, el **importe convertido no cambia** y NO aparece el «≈». El log de DEBUG imprime cuántas curó en el sitio y cuántas reabrió |

---

## Al terminar cada ticket

- **No inventes un PASS.** Si no se pudo comprobar, se dice qué faltó y se queda en `qa/`.
- Lo verificado se mueve a `tickets/done/` con su evidencia, y se actualiza `docs/TICKETS.md` (los
  conteos y la fila) — el índice se comprueba con un diff contra el disco, no a ojo.
- Si tocaste código para arreglar algo, `lastVerified` del área en `qa/coverage-index.json` va en el
  **mismo commit**.
