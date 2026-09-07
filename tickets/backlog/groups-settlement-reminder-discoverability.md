---
id: groups-settlement-reminder-discoverability
status: backlog
priority: medium
area: groups
created: 2026-09-07
updated: 2026-09-07
---

# El recordatorio de deuda no tiene ningún camino de descubrimiento

## Problema

El recordatorio de liquidación (`groups-settlement-reminder`) quedó construido y correcto, pero
**hoy no lo va a recibir prácticamente nadie**, y no por un bug: por la suma de tres decisiones
que por separado son razonables.

1. **`groupSettlementRemindersEnabled` nace en `false`.** Es deliberado y se sostiene: es el
   único aviso de la app que habla del dinero que le debes a otra persona, y encenderlo sin
   pedirlo convertiría una actualización en un cobro sorpresa.
2. **No entra en el primer de notificaciones.** `NotificationPrimerSheet.acceptNotifications()`
   es donde se enciende `budgetAlertsEnabled` —el hermano del que se copió el default— junto con
   todos los `NotificationItem`. El toggle nuevo no está ahí: **se heredó el default de su
   hermano sin heredar su encendido**, y ese es el desequilibrio real.
3. **Hay un segundo interruptor que la tarjeta no menciona.** El servicio exige además el
   `NotificationItem` de tipo `.groups` activo, que también nace apagado. Quien encienda
   «Recordatorios de deudas» con los avisos de Grupos apagados **no recibe nada, en silencio**.
   La subordinación es correcta (quien apaga Grupos espera no recibir avisos de grupo) pero es
   invisible: no hay `.disabled()`, ni nota al pie, ni nada en el hint.

Y el banner in-app dentro del grupo —que el owner marcó como acompañamiento opcional y el ticket
padre descartó para la V1— era la única pieza que lo habría hecho descubrible desde dentro del
producto. No construirlo fue correcto; lo que queda es que **no hay ninguna otra vía**.

## Lo que hace falta decidir (Jürgen)

Tres preguntas, y solo la primera es de producto de verdad:

1. **¿El nudge entra en el primer de notificaciones?** Es decir, ¿cuando alguien acepta recibir
   avisos, acepta también este? A favor: es donde ya está diciendo «sí, avísame», y es lo que
   hace inocuo el default OFF de su hermano. En contra: este habla de deudas con personas, no de
   presupuestos propios, y puede querer un consentimiento aparte.
2. **¿La tarjeta debe deshabilitarse cuando los avisos de Grupos están apagados?**
   (`.disabled(!groupsMasterActive)` + una línea explicándolo), o basta con añadir la
   dependencia al texto del hint. Lo segundo es más barato y toca 16 `.lproj`.
3. **¿Se construye el banner in-app** del ticket padre como complemento, o se deja fuera?

## Acceptance Criteria

- [ ] Existe al menos un camino por el que un usuario con grupos y deudas descubra el feature.
- [ ] Un toggle encendido que no puede entregar nada se lo dice al usuario, o no se puede encender.
- [ ] La decisión queda escrita en el ticket, no solo aplicada en el código.

## Notas

Sale de la review adversarial del 2026-09-07 (lente de producto), no de un fallo funcional: el
feature cumple sus AC y está pinneado. Es una decisión de producto que el ticket padre no
planteó porque el default se copió sin mirar de dónde venía su encendido.
