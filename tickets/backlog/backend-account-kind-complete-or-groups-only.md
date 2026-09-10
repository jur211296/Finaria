---
id: backend-account-kind-complete-or-groups-only
status: backlog
priority: high
area: "gateway, modo-nube, groups"
created: 2026-09-09
source: "ADR 2026-09-09 «Sesiones — dos ejes» §11"
---

# El backend tiene que saber decir si una cuenta es «completa» o «solo grupos»

## El problema, en lenguaje de usuario

Entro con mi cuenta de Google en un móvil recién instalado. Yala no puede saber si esa cuenta lleva
mis finanzas personales o solo mis grupos: hoy lo deduce de una preferencia local (`storageMode`) que
en un móvil nuevo no existe. Así que cada puerta se lo inventa a su manera: «Ya tengo cuenta» me
adopta como si fuera completa; «Vengo por un grupo» me trata como solo-grupos aunque tenga años de
datos en la nube.

## Lo medido (2026-09-09, árbol `3a94604e`)

- `GET /account/exists` (`gateway/src/sync/account.ts:255-262`) responde `{ exists: bool }` mirando si
  hay fila en `profiles`. Nada más.
- El cliente deriva «dónde viven mis datos» de `storageMode` local: `YalaAccountLogic.model`
  (`Yala/App/Logic/YalaAccountLogic.swift`, `dataLocation: isCloud ? .cloud : .groupsOnly`) y
  `RestoreRouter.decide` (`RestoreDestination.swift`, por `onboardingMode`).
- El sign-in de grupos (`GroupsSignInView`) no consulta al backend nada sobre la cuenta.

## Lo que se espera

Una cuenta en la nube tiene un **tipo** conocido por el servidor:

| kind | qué significa |
|---|---|
| `complete` | lleva finanzas personales (nació en la nube, o se activó Yala completo en la nube) |
| `groups_only` | solo grupos (nació por «Vengo por un grupo», o es la cuenta asociada de una sesión privada) |

y el cliente lo lee en el bloque [I] para rutear (ticket `cloud-sign-in-discovers-account-kind`).

## Alcance

1. **Esquema:** columna `kind` en `profiles` (Supabase), `text not null default 'groups_only'`, check
   `in ('complete','groups_only')`. Migración de las cuentas existentes: `complete` si tienen corpus
   personal sincronizado (medir en staging qué tabla/contador lo prueba antes de escribir la migración;
   no deducirlo del `storageMode` de nadie). RLS: legible por el dueño; escribible solo por RPC.
2. **Wire:** `GET /account/exists` pasa a devolver `{ exists, kind? }` (campo ausente ⇒ cliente trata
   como `groups_only`, fail-safe hacia la opción menos invasiva). `POST /account/claim` acepta `kind`
   (born-cloud lo manda `complete`; el alta de grupos, `groups_only`). Un endpoint o RPC para
   **promover** `groups_only → complete` (lo usa «Activar Yala completo → nube»). No hay degradación
   `complete → groups_only`: se hace con «Vaciar datos» + política aparte, fuera de este ticket.
3. **Cliente:** `CloudAccountClient.exists` decodifica `kind`; `CloudWelcomeSignInFlow.route` devuelve
   `.accountFound(kind:)`; `YalaAccountLogic.dataLocation` y `RestoreRouter` dejan de inferir y leen el
   `kind` cacheado de la sesión (persistido en el mismo sitio que el provider de la sesión).
4. **Staging primero** (runbook de DDL en la memoria del agente / `docs/`), golden tests del gateway
   contra staging, y después prod.

## Criterios de aceptación

- [ ] `GET /account/exists` en staging devuelve `kind` para una cuenta nacida en la nube (`complete`) y
      para una de solo-grupos (`groups_only`); para una cuenta inexistente, `exists: false` sin `kind`.
- [ ] El claim born-cloud crea `complete`; el alta de grupos crea `groups_only`.
- [ ] Promover funciona una vez y es idempotente; jamás degrada.
- [ ] Todas las cuentas de producción tienen `kind` tras la migración, y el conteo por tipo se anota en
      el PR (medido, no estimado).
- [ ] Tests del gateway (`gateway/test/`) para las tres rutas; `CloudAccountClientTests` para el decode
      con y sin `kind`.

## Fuera de alcance

El ruteo del cliente con ese dato (ticket siguiente). La UI.
