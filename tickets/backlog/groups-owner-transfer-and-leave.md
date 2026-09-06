---
id: groups-owner-transfer-and-leave
status: backlog
priority: high
area: groups
created: 2026-09-06
updated: 2026-09-06
source: decisión de Jürgen del 2026-09-06 sobre tickets/qa/groups-leave-rpc-error-10.md
---

# El dueño de un grupo con deuda puede transferirlo y salir

## Qué le pasa al usuario

Soy el dueño de un grupo y quiero irme. «Salir» no está (soy el dueño) y «Eliminar grupo» está
deshabilitado porque hay deuda pendiente — aunque la deuda sea entre otras dos personas y no mía. Me
quedo dentro sin salida y con un aviso que me pide liquidar deudas que no son mías.

## Decisión Jürgen (2026-09-06)

**Ofrecer «Transferir y salir».** Elegida entre: (a) transferir y salir, (b) permitir eliminar con
deuda como ya se permite salir con deuda, (c) dejarlo. Motivo, tal como se le puso delante y ratificó: el RPC de transferencia **ya existe en el
servidor**, falta solo la hoja en iOS, y el grupo con sus deudas sigue vivo para los demás. Descartó (b)
porque borra deudas de terceros y es irreversible. **«Eliminar» sigue bloqueado con deuda.**

## Punto de partida (del ticket padre, NO re-medido aquí — greppear antes)

- El servidor rechaza la salida del dueño con `yala_owner_cannot_leave` (`leave_group` en
  `supabase-groups-staging.ddl`); el RPC de transferencia de propiedad existe según
  `groups-leave-rpc-error-10` («el RPC ya existe, falta UI»). **Confirmar nombre y contrato del RPC
  en el DDL de prod antes de escribir la hoja.**
- `SplitGroup.isOwner` es device-local y solo lo escribe el creador; la pantalla ya dejó de decidir con
  ese flag (arreglo del padre). La nueva acción debe usar la misma fuente de verdad server-side.
- El bloqueo de «Eliminar» mira la deuda de todo el grupo (medido en el padre). No cambia con esta
  decisión, pero el copy que acompaña al bloqueo no debe decirle al dueño que liquide deudas ajenas:
  debe ofrecerle la transferencia.

## Criterio de hecho (AC)

- [ ] En la pantalla del grupo, el dueño ve «Transferir y salir» cuando hay al menos otro miembro
      **activo**; elige a quién y confirma. Tras el RPC, él ya no es miembro y el elegido es el dueño
      (para todos, tras el pull).
- [ ] Con deuda pendiente, «Eliminar» sigue deshabilitado y el aviso ofrece la transferencia en vez
      de pedirle liquidar deudas de otros.
- [ ] Si es el único miembro activo, no se ofrece transferir: se ofrece eliminar (ya existe).
- [ ] Cada error del RPC tiene copy propio (mismo contrato que el padre: nunca un número crudo).
- [ ] Copy en 16 `.lproj`. Unit para la lógica pura de «qué acción se ofrece» (dueño/único/deuda).
- [ ] **Review adversarial** (toca membresías y sync) y **device-QA con dos teléfonos** sobre una
      subida posterior.

## Relacionados

- [[groups-leave-rpc-error-10]] — el padre, en `qa/`; ahí está la medición del `10` y del `isOwner`.
