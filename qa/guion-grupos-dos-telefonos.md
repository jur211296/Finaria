# Guion de device-QA · Grupos, dos teléfonos

> **Qué es esto.** La secuencia ejecutable del cluster de Grupos: invitación → entrada → aprobación
> → gasto → salida. Está ordenada para que **un solo montaje cierre el máximo de tickets**, y para
> que los estados que se gastan una sola vez (una instalación virgen) se exploten antes de gastarlos.
>
> `qa/guion-tanda.md` sigue siendo el **índice por montaje** de toda la cola. Este fichero es el
> guion de UNA de esas casillas, la más cara de montar.
>
> **Escrito el 2026-09-09** contra el árbol de `2.1` en el commit del build 13 (`039a12ed`).
> Los literales de UI están citados de `Yala/Resources/es-419.lproj/Localizable.strings` de ese árbol.

---

## Antes de nada: qué necesita DOS TELÉFONOS y qué no

Medido ticket a ticket el 2026-09-09. **La mitad de lo que la cola daba por «device-QA» no necesita
dos aparatos**, y separarlo es lo que hace corto este guion.

| Necesita | Por qué | Tickets |
|---|---|---|
| **2 teléfonos + TestFlight (prod)** | APNs real con la app cerrada; el estado final es «sonó un banner» y eso no se siembra | `aviso-de-nuevo-miembro-no-llega-hasta-abrir-la-app` · `groups-expense-notif-only-on-foreground` · `rejoin-tap-renotifies-admins` |
| **2 CUENTAS, no 2 aparatos** | Hace falta una segunda identidad con sesión real, no un segundo teléfono. Dos simuladores contra **staging** (`ENFORCE = "observe"`) dan el mismo estado | `groups-owner-transfer-and-leave` · `guest-decline-has-no-screen` · `rejected-member-cold-tap-does-nothing` · `groups-archived-group-rejects-join` · `groups-equal-split-shows-not-participating-on-peer` |
| **1 dispositivo** | El estado se siembra reinstalando y volviendo a entrar con la misma cuenta | `groups-leave-rpc-error-10` · `groups-deleted-group-detail-stays-open` |
| **Simulador, sin Jürgen** | Sembrable hoy; no debería estar en una cola de device | `group-joiner-flag-consumers-still-narrow` · `invite-link-five-causes-one-message` (P2/P3/P5) · `invite-backend-stale-config` (casos A y B) |
| **Fuera del guion** | La parte de rendimiento no es medible a mano; el otro es un spec, no un caso | `groups-tab-missing-panel-perf` · `groups-consent-door-spec` |

**El aparato real es obligatorio contra producción** porque `gateway/wrangler.toml:91` pone
`ENFORCE = "enforce"` y `ATTEST_ENV = "production"`: App Attest rechaza cualquier cliente no
atestado, y el simulador no atesta. Contra **staging** (`:32`, `ENFORCE = "observe"`) eso no aplica —
de ahí la segunda fila de la tabla.

---

## Las cuatro trampas que producen un FAIL falso

Van arriba porque cada una cuesta una tanda entera.

1. **El token de push solo se sube al arrancar.** `AppBootstrapper.swift:371` llama
   `PushTokenRegistrar.shared.attemptUpload()` **solo en el boot**. Si el receptor acaba de iniciar
   sesión y no ha relanzado la app, **no hay token registrado y no llega nada** — y eso no se
   distingue de un fallo de entrega. ⇒ tras iniciar sesión, cerrar la app del todo y volver a abrirla.
2. **El rate-limit de avisos de grupo es de 5 min y persiste entre arranques.**
   `GroupNotificationService.swift:44-47` (`rateLimitInterval = 300`), guardado en `UserDefaults` bajo
   `GroupNotifications.lastNotified.<groupID>`. Es **por grupo**: por eso este guion usa **dos grupos**,
   y así no hay que esperar entre tramos.
3. **Para contar banners, el receptor tiene que estar encendido y mirando entre taps.**
   *(Medido el 2026-09-09, y corrige una versión anterior de esta nota que decía que APNs los colapsa
   por `collapse-id`: **el gateway no manda esa cabecera**. `gateway/src/push/apns.ts:116-128` envía
   `apns-topic`, `apns-push-type`, `apns-priority`, `apns-expiration` y `content-type`, y ninguna más.)*
   El motivo real es más simple: con `apns-expiration` a 24 h, un teléfono que estuvo fuera recibe
   **la ráfaga entera de golpe al volver**, y ahí ya no se distingue «llegaron cuatro» de «llegó uno y
   se repitió en pantalla». Contar en vivo es lo único que da un número fiable.
4. **`hasCompletedOnboarding` es por dispositivo.** Si el teléfono B viene de reinstalar, la hoja de
   invitación sale con el **campo vacío y sin «Más tarde»** (`canDecline == hasCompletedOnboarding`,
   `GroupInviteOnboardingView.swift:223`). **Eso es correcto, no un FAIL** — es el contra-caso.

---

## Fase 0 · Montaje

**Teléfono A** — el personal, Apple ID `jur211296@gmail.com`. Está en el grupo interno *y* en el
externo, así que ve el build 13.

**Teléfono B** — el de QA, Apple ID `test@yala-app.pe`. Está **solo en el grupo externo**. El build 13
tiene `externalBuildState: IN_BETA_TESTING` (medido por API el 2026-09-09), así que **debería verlo**;
el encargo suponía que no. Se confirma en 5 segundos abriendo TestFlight en B.

1. **A**: TestFlight → instalar build 13 → abrir Yala → completar el alta → iniciar sesión.
2. **A**: entrar en Grupos y **aceptar** el permiso de notificaciones. El permiso se pide **ahí**, no en
   el alta (`GroupsContainerView.swift:578-586`); si ya se denegó antes, sale un alert y hay que ir a
   *Ajustes → Yala → Notificaciones*.
3. **A**: cerrar Yala del todo y volver a abrirla → sube el token de push (trampa 1).
4. **B**: **borrar** Yala del teléfono, reinstalarla desde TestFlight y **no abrirla todavía**.
   El primer arranque se gasta en la Fase 1.
5. Opcional pero barato: `wrangler tail --env production` en una terminal. Es la señal que separa
   «el servidor no emitió» de «Apple no entregó».

---

## Fase 1 · B virgen — el primer arranque (2 tickets)

Este estado **se gasta al usarlo**: sin reinstalar no vuelve. Por eso va primero.

- **A**: crear el grupo **G1** → miembros → compartir enlace → mandarlo a B.
- **B**: abrir el enlace **en los primeros segundos del primer lanzamiento**, antes de que termine el
  refresco de arranque.

**PASS** — `invite-refresh-forzado-es-noop-si-hay-otro-en-vuelo`: B avanza **sin ninguna alerta**.
**FAIL**: «Hubo un problema con el grupo» / «No pudimos abrir esta invitación ahora. Guardamos tu
solicitud: vuelve a intentarlo en un momento.»

**PASS** — contra-caso de `groups-invite-skips-unirme-sheet-if-onboarded`: la hoja sale con el campo
**«Tu nombre» vacío** y **sin** «Más tarde». Es lo correcto en un teléfono recién instalado (trampa 4).

Luego: **B completa el alta e inicia sesión**, entra en Grupos, **acepta** las notificaciones, y
**cierra y reabre la app** (trampa 1). B queda configurado para el resto del guion.

---

## Fase 2 · La hoja de invitación y el aviso al admin (3 tickets)

**Antes de que B toque nada: A cierra Yala del todo y bloquea el teléfono.** Es la única forma de
comprobar el aviso con la app cerrada, y solo se puede hacer una vez por grupo (trampa 2).

- **A**: generar un enlace **nuevo** de G1 (el anterior ya quedó confirmado).
- **B**: con la app matada, tapear el enlace.

**PASS** — `groups-invite-skips-unirme-sheet-if-onboarded`: sale la hoja **«Te invitaron al grupo G1»**
con el campo **prerrellenado** con el nombre del perfil y **dos** botones: «Unirme al grupo» y
**«Más tarde»**. Y — esto es lo que discrimina de verdad — **a A no le llega nada hasta que B toca
«Unirme al grupo»**.

**PASS** — `invite-link-five-causes-one-message` (P2): la hoja trae el **nombre, icono y color** del
grupo, no «Te invitaron a un grupo» con el color del tema.

**B** toca «Unirme al grupo» → debe ver **«Solicitud enviada»**.

**PASS** — `aviso-de-nuevo-miembro-no-llega-hasta-abrir-la-app`: **sin tocar A**, en su pantalla de
bloqueo suena y aparece **«👋 Alguien quiere unirse a uno de tus grupos»**. Si la app despierta, se
sustituye por **«👋 <B> quiere unirse a G1»** / «Puedes aprobar o rechazar desde Yala.»
**FAIL**: silencio, y el aviso aparece solo al abrir la app a mano.
**No cuenta como PASS** que salga justo al desbloquear. Y **tocar el banner no lleva al grupo**: eso
es esperado hoy, no un fallo.

---

## Fase 3 · Los taps repetidos (1 ticket)

- **A**: encendido y mirando, **sin aprobar ni rechazar** (trampa 3).
- **B**: tapear el **mismo** enlace **3 veces más**, con unos segundos entre taps.

**PASS** — `rejoin-tap-renotifies-admins`: a A le llega **exactamente un** aviso en total, el del
primer tap. **FAIL**: cuatro avisos idénticos.

---

## Fase 4 · Rechazo y vuelta a pedir (2 tickets)

- **A**: detalle de G1 → «Solicitudes pendientes» → **«Rechazar»** → confirmar
  («¿Rechazar la solicitud de <B>? Podrá volver a pedir acceso si recibe otro enlace.»).
- **B**: volver a la lista de grupos y hacer **pull-to-refresh**.

**PASS** — `guest-decline-has-no-screen`: G1 **sigue en la lista** con chip **«Solicitud rechazada»**.
Al tocar la tarjeta sale el alert **«¿Salir del grupo?»** con el cuerpo «Tu solicitud fue rechazada.
Si sales del grupo, se eliminará de tu lista. Tus registros personales se mantienen.» y botón
destructivo **«Salir del grupo»**. Al confirmar, **el grupo desaparece sin alert de Error** — esa es la
aserción que carga el peso. **Ojo**: la tarjeta del rechazado **no navega al detalle**, así que se ve
chip + alert y no el banner interno. No apuntarlo como FAIL.
De paso, mirar si a B le llega **«Novedades sobre tu membresía en un grupo»**: resuelve un punto que el
ticket daba por inexistente y quedó desfasado el 2026-09-03.

- **A**: generar un enlace **nuevo**.
- **B**: **matar la app** (swipe up) y tapear ese enlace.

**PASS** — `rejected-member-cold-tap-does-nothing`: la solicitud llega y A vuelve a ver a B en
«Solicitudes pendientes», **una sola vez**. **FAIL**: no pasa nada.
**Control que prueba el mecanismo**: B mata y **reabre** la app **sin tapear nada** → **no** debe
generarse ninguna solicitud. Si aparece una fantasma, el arm se está persistiendo y está mal.
**Control de no-sobre-corrección**: este mismo tramo demuestra que la Fase 3 no apagó de más.

---

## Fase 5 · Dentro del grupo: identidad y gasto (2 tickets)

- **A**: aprobar a B («¿Aprobar a <B> como miembro del grupo?»).
- **B**: abrir G1 **sin relanzar la app en ningún momento** — esa es toda la precondición.
- **A**: crear un gasto en G1, **pagado por A**, con reparto igualitario.

**PASS** — `groups-equal-split-shows-not-participating-on-peer`: en B, la fila del gasto muestra su
parte real (**«Te prestaron»** + monto) en el feed **y** en el detalle. **FAIL**: el literal
**«No participaste»** en un gasto que A muestra mitad y mitad. Si la identidad aún no resuelve, la
fila sale **vacía** — eso es el comportamiento nuevo y correcto, no un FAIL.
**Ruido esperado**: para alguien recién unido, el saldo de la tarjeta sale vacío y «Pagado por» no
viene puesto. Es `group-joiner-flag-consumers-still-narrow`, otro ticket. No es recaída.

Para el aviso del gasto, **usar el grupo G2** (trampa 2: G1 ya gastó su ventana de 5 min):

- **A y B** ya están juntos en G2 (repetir invitación, o crearlo antes en paralelo).
- **B**: app en segundo plano, sin matarla. Luego repetir con B **force-quit**.
- **A**: crear un gasto en G2.

**PASS** — `groups-expense-notif-only-on-foreground`: B ve un banner del sistema titulado **«Grupos»**
con cuerpo **«Novedades en tus grupos»**, sin abrir la app y también con la app matada. Si iOS despierta
la app, se sustituye por **«🧾 A agregó '<gasto>' — te toca <monto>»**. A, el autor, **no recibe nada**.
**Esperado, no FAIL**: pueden verse **dos** avisos (el remoto y el rico local) — no hay dedup entre
ellos, así que el AC «una sola vez» del ticket probablemente cae. Anotarlo como tal.

---

## Fase 6 · Archivado (1 ticket)

- **A**: G1 → Ajustes del grupo → **Archivar grupo** → confirmar.
- **B**: tapear el enlace de G1.

**PASS** — `groups-archived-group-rejects-join`: alert **«G1 fue archivado»** / «Su admin lo archivó y
ya no acepta cambios.», con botón **«Aceptar»**.
**FAIL** con matices: **«Enlace no válido»** = cayó en el mapeo equivocado; **«Hubo un problema con el
grupo»** = cayó en el otro. Los tres son pantallas distintas y hay que distinguirlas.

- **A**: **Desarchivar**. **B**: volver a tapear → debe entrar **como pendiente**. Eso cierra la
  reversibilidad.

---

## Fase 7 · Salir y transferir (2 tickets)

- **A**: G1 → Ajustes del grupo → mirar el hint bajo «Eliminar grupo» → **«Transferir y salir»**.

**PASS** — `groups-owner-transfer-and-leave`: existe el botón **«Transferir y salir»** con el hint «El
grupo sigue activo con sus saldos. Tú dejas de ser miembro.», y el diálogo **nombra al heredero**:
«<B> pasa a quedarse al frente del grupo y tú sales. Los saldos pendientes siguen como están.» Con
saldo propio, añade «Ojo: sales con un saldo pendiente. La otra parte seguirá viendo esa deuda.»
**Este es el ticket que la cola daba por bloqueado por falta de teléfono y no lo estaba**: lo que
faltaba era un co-miembro con cuenta real, que aquí ya existe (B).

Para `groups-leave-rpc-error-10` hace falta la divergencia de ownership, que **se siembra en un solo
teléfono**: A crea un grupo → borra y reinstala Yala → vuelve a entrar con su cuenta. El pull recrea el
grupo y **nunca escribe `isOwner`**, así que queda local en `false` con el servidor diciendo lo
contrario. Entonces: Ajustes del grupo → **«Salir del grupo»**.

**PASS**: alert **«Este grupo es tuyo, así que no puedes salir: alguien tiene que quedarse al frente.
Si ya no lo necesitas, puedes eliminarlo.»** y, al cerrarlo, la pantalla **se repinta como dueño**:
desaparece «Salir del grupo» y **aparece «Eliminar grupo»**.
**FAIL**: **«No se ha podido completar la operación. (Error de Yala.GroupsRPCError 10.)»**

---

## Registro

- **No se inventa un PASS.** Lo que no se pudo mirar se dice y el ticket se queda en `qa/`.
- Cada veredicto va al ticket en su sección `## QA Visual`, con fecha y build (13).
- Lo verificado se mueve a `tickets/done/` y se actualiza `docs/TICKETS.md` (conteos y fila).
- Lo que salga de camino y no sea de este cluster **abre ticket propio**, no se queda en el PR.
