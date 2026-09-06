---
id: groups-owner-debt-no-heir-dead-end
status: backlog
priority: high
area: groups
created: 2026-09-06
updated: 2026-09-06
source: review adversarial de groups-owner-transfer-and-leave (2026-09-06)
needs: decisión de producto de Jürgen
---

# El dueño con deuda y SIN heredero sigue sin salida

## Qué le pasa al usuario

Soy el dueño de un grupo, hay saldos pendientes y **no hay nadie a quien cederle el grupo**. Entonces:

- **«Salir»** no se me ofrece — el servidor lo rechaza con `yala_owner_cannot_leave`.
- **«Transferir y salir»** no se me ofrece — no hay heredero elegible.
- **«Eliminar»** está deshabilitado — hay deuda en el grupo.

Las tres salidas cerradas. La app me lo dice con honestidad («hay saldos pendientes en el grupo»),
pero no me da nada que hacer.

## Cómo se llega ahí (tres caminos, los tres alcanzables)

Medido en la tabla de verdad de `GroupOwnerExitLogic.offer` durante la review de
[[groups-owner-transfer-and-leave]]:

1. **Único miembro activo, con saldo vivo de alguien que ya se fue.** `recomputeOutstandingDebt`
   fetcha **todos** los miembros de la zona sin filtrar por `isActive`, y
   `GroupBalanceService.calculateBalances` construye sus claves desde los mapas `paid`/`owes`, no
   desde el array de miembros ⇒ un miembro que salió con saldo sigue produciendo `netBalance ≠ 0`.
2. **Canal CloudKit-legacy.** Hay co-miembros de sobra, pero CKShare no sabe ceder ownership.
3. **Co-miembros sin cuenta** (`user_id NULL`): grupo migrado y no reclamado. No hay `auth.user` al
   que ceder.

## Por qué NO se resolvió en el ticket que lo destapó

La decisión de Jürgen del 2026-09-06 fue «Transferir y salir», y **descartó explícitamente** permitir
eliminar con deuda («borra deudas de terceros, es irreversible»). Esa decisión cubre el caso con
heredero y deja esta celda fuera. Inventar aquí una cuarta salida sería decidir por él.

## Salidas posibles (para que elija, no recomendación cerrada)

- **(a) Dejarlo como está.** El hint es honesto y el caso es raro. Coste cero, y el dueño sigue
  atrapado.
- **(b) Permitir eliminar cuando la deuda es SOLO con miembros inactivos.** Ataca el camino 1, que es
  el más probable de los tres, sin tocar el principio que Jürgen protegió (nadie pierde una deuda
  viva con alguien que sigue en el grupo). Requiere separar «deuda del grupo» de «deuda entre
  miembros activos» — hoy el bloqueo mira todos los saldos sin distinguir.
- **(c) Ofrecer archivar como salida.** «Archivar» ya funciona con deuda y hoy está en la pantalla;
  no le saca del grupo, pero se lo quita de la lista. Es la salida más barata y la menos completa.
- **(d) Ofrecer liquidar desde aquí.** Un atajo a la pantalla de saldos. No desbloquea nada por sí
  solo si la deuda es entre terceros.

## Criterio de hecho (AC)

- [ ] Decisión de Jürgen escrita en este ticket.
- [ ] Si la decisión cambia el bloqueo, `GroupOwnerExitLogic` gana el caso y su test.
- [ ] Copy en 16 `.lproj` si aparece texto nuevo.

## Relacionados

- [[groups-owner-transfer-and-leave]] — el ticket que lo destapó y cubre la celda CON heredero.
- [[groups-leave-rpc-error-10]] — el abuelo: el callejón original del dueño.
