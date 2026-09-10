---
id: reverse-cutover-cerrado-para-cuentas-born-cloud
status: backlog
priority: high
area: "modo-nube, gateway, onboarding"
created: 2026-09-10
source: "review adversarial de `backend-account-kind-complete-or-groups-only` (2026-09-10) — hallazgo B4"
---

# «Volver a iCloud» no está disponible para quien nació en la nube, y tras el fresh start eso es todo el mundo

## El problema, en lenguaje de usuario

Creo mi cuenta de Yala con Google y uso la app durante meses. Un día decido que prefiero que mis datos
vivan solo en mi iCloud privado. Voy a Ajustes a «Volver a iCloud»… y no hay salida: el backend
rechaza la operación. La única forma de dejar de tener mis finanzas en la nube es borrar la cuenta y
empezar de cero.

## Lo medido (2026-09-10, contra staging y producción)

- `migration_progress`, rama `reverse_claim`, tiene un guard duro al principio: si `migrated_at is
  null` devuelve `{ok:false, reason:'not_migrated'}`. Es deliberado y está comentado: «Only a migrated
  account can reverse (born-cloud v1 excluded)».
- `migrated_at` **solo lo estampa el `cutover`**, es decir, la migración de una sesión privada
  existente hacia la nube. Una cuenta que nace en la nube nunca pasa por ahí.
- Las dos cuentas de producción de antes del fresh start **no tenían `migrated_at`**: lo dice la
  propia sección de decisiones del ticket 2 («lo personal nació en la nube y no tiene copia en
  CloudKit»). Tras el fresh start del 2026-09-10, **toda cuenta nueva es born-cloud**.
- El golden 11 de `gateway/test/account.goldens.test.ts` pinnea justamente ese rechazo, así que el
  comportamiento está fijado por un test: cambiarlo es una decisión, no un descuido.

## Por qué importa ahora, y no antes

El ADR del 2026-09-09 apoya en la reversa una pieza del modelo nuevo: es la **única degradación**
`complete → groups_only` permitida (fila E de `docs/sessions/2026-09-09-matriz-escenarios-sesiones.md`).
El ticket `backend-account-kind-complete-or-groups-only` implementó esa mitad —`reverse_complete` ya
escribe `kind='groups_only'` y el cliente lo refresca—, pero **la puerta que lleva hasta ahí está
cerrada para la población real**: nadie puede llegar a ejecutar esa degradación.

O sea: la fila E de la matriz promete algo que hoy no se puede recorrer, y la única vía por la que una
cuenta pasa a `groups_only` desde `complete` es inalcanzable.

## Lo que hay que decidir (es de Jürgen, no técnico)

1. **¿«Volver a iCloud» debe existir para cuentas nacidas en la nube?** El modelo del ADR dice que sí
   («la sesión privada no es obligatoria», y el eje privado × nube es libre), pero abrirlo no es
   gratis: para una cuenta migrada, «volver» significa restaurar un CloudKit que YA tiene el corpus;
   para una born-cloud significa **exportar por primera vez** todo a iCloud, que es otra operación.
2. Si la respuesta es que no, entonces la fila E de la matriz y el §11 del ADR deben decir que la
   degradación es v-futura, y este ticket se cierra como decisión registrada.

## Alcance si se abre

- Quitar o condicionar el guard `not_migrated` de `reverse_claim`, con el camino de export a CloudKit
  que hoy no existe para una cuenta que nunca tuvo mirror.
- Revisar el golden 11, que pinnea el rechazo.
- Revisar `ReverseEligibility` en el cliente (hoy oculta o rechaza la opción por el mismo motivo).

## Criterios de aceptación

- [ ] Decidido por Jürgen si la reversa se abre a born-cloud o si la degradación queda como v-futura.
- [ ] Si se abre: una cuenta born-cloud completa el ciclo y termina en `kind='groups_only'` con lo
      personal en iCloud, verificado contra staging.
- [ ] Si no se abre: el ADR §11 y la fila E de la matriz lo dicen, y el ticket se cierra como
      `discarded` con el motivo.

## Fuera de alcance

El `kind` en sí, que ya está implementado y verificado por su lado.
