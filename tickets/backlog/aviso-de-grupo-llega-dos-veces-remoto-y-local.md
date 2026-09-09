---
id: aviso-de-grupo-llega-dos-veces-remoto-y-local
status: backlog
priority: medium
area: "groups, notifications, push"
created: 2026-09-09
source: guion de device-QA de Grupos del 2026-09-09 (hallazgo de camino)
---

# Un cambio en un grupo puede dejar DOS avisos en el Centro de Notificaciones: el remoto y el local

## Qué pasa

Desde que el servidor manda un push de **alerta** por los cambios de grupo, hay dos emisores para el
mismo hecho y **nada los reconcilia**:

1. **El remoto.** iOS pinta el banner genérico en cuanto llega («Grupos» / «Novedades en tus grupos»),
   sin que la app tenga que estar viva.
2. **El local.** Cuando la app despierta y hace el pull, `GroupNotificationService` construye el aviso
   rico («🧾 X agregó '…' — te toca …») y lo entrega con
   `NotificationService.sendNotification` (`GroupNotificationService.swift:125`).

El segundo **no reemplaza** al primero. Medido en el árbol del build 13 (`039a12ed`):

- `NotificationService.swift:246` crea cada request con
  `identifier: "notification-\(UUID().uuidString)"` — **un id nuevo cada vez**, así que iOS lo trata
  como una notificación distinta y la añade en lugar de sustituirla.
- El gateway **no manda `apns-collapse-id`**: `gateway/src/push/apns.ts:116-128` envía `apns-topic`,
  `apns-push-type`, `apns-priority`, `apns-expiration` y `content-type`, y nada más.
- Los dos limpiadores de entregadas que existen son de **fronteras de cuenta**, no de dedup:
  `clearDeliveredNotifications` (sign-out / sesión secundaria) y `clearDeliveredGroupNotifications`
  (cierre de sesión solo-grupos), `NotificationService.swift:412-433`.

## Por qué importa

El ticket `groups-expense-notif-only-on-foreground` lleva un AC que pide que el aviso llegue **«una
sola vez»**. Tal como está el código, ese AC **no se puede cumplir** cuando la app despierta después
del banner remoto — y quien haga el device-QA lo va a apuntar como FAIL del fix, cuando en realidad es
un defecto **distinto y posterior**: el fix del banner hizo aparecer un segundo emisor que antes no
existía.

Hay un segundo efecto, más pequeño: el rate-limit de 5 min por grupo
(`GroupNotificationService.swift:44-47`) gobierna **solo** al emisor local. El banner remoto no pasa
por él, así que dos cambios seguidos del mismo grupo dan **dos** banners genéricos.

## Qué haría falta

Decidir cuál de los dos manda y hacer que el otro se retire:

- **Opción A** — que el local **sustituya** al remoto: darle al request local un identifier
  determinista por grupo (p. ej. `group-<uuid>`) y que el payload remoto use el mismo `apns-collapse-id`.
  iOS reemplaza en sitio y queda un aviso, el rico.
- **Opción B** — que el local **retire** al remoto: al construir el rico, llamar a
  `removeDeliveredNotifications` sobre las entregadas de ese `deepLink` antes de entregar. Ya existe la
  maquinaria para filtrar por `groups/` en `clearDeliveredGroupNotifications`.

La A es más limpia (una sola entrega, sin parpadeo) pero toca cliente **y** gateway. La B es solo
cliente. **Decisión de producto**: si se prefiere que el usuario vea el genérico al instante y el rico
lo sustituya al abrir, es la A.

## Cómo se comprueba

Con dos cuentas: el receptor con la app **matada**, el otro crea un gasto. Ver el banner genérico,
abrir la app, y mirar el Centro de Notificaciones. Hoy deben quedar **dos** entradas del mismo hecho.
