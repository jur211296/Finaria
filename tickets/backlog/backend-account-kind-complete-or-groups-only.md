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
   **promover** `groups_only → complete` (lo usa «Activar Yala completo → nube»). **Una sola degradación**
   `complete → groups_only`, como efecto del **reverse cutover existente** («Volver a iCloud»,
   `POST /account/migration` `reverse_*`): lo personal vuelve a iCloud y la cuenta queda como cuenta de
   grupos **asociada** a esa sesión privada si tiene grupos. Ninguna otra ruta degrada. La
   **promoción** `groups_only → complete` la usan «Activar Yala completo → nube» y «migrar a la nube»
   desde una sesión privada que ya tiene cuenta asociada (misma cuenta, nunca una segunda).
3. **Cliente:** `CloudAccountClient.exists` decodifica `kind`; `CloudWelcomeSignInFlow.route` devuelve
   `.accountFound(kind:)`; `YalaAccountLogic.dataLocation` y `RestoreRouter` dejan de inferir y leen el
   `kind` cacheado de la sesión (persistido en el mismo sitio que el provider de la sesión).
4. **Staging primero** (runbook de DDL en la memoria del agente / `docs/`), golden tests del gateway
   contra staging, y después prod.

## Criterios de aceptación

- [ ] `GET /account/exists` en staging devuelve `kind` para una cuenta nacida en la nube (`complete`) y
      para una de solo-grupos (`groups_only`); para una cuenta inexistente, `exists: false` sin `kind`.
- [ ] El claim born-cloud crea `complete`; el alta de grupos crea `groups_only`.
- [ ] Promover funciona una vez y es idempotente. Degradar solo ocurre dentro del reverse cutover y deja
      `groups_only`; un `complete` con corpus personal vivo nunca se degrada por otra vía.
- [ ] Todas las cuentas de producción tienen `kind` tras la migración, y el conteo por tipo se anota en
      el PR (medido, no estimado).
- [ ] Tests del gateway (`gateway/test/`) para las tres rutas; `CloudAccountClientTests` para el decode
      con y sin `kind`.

## Fuera de alcance

El ruteo del cliente con ese dato (ticket siguiente). La UI.

## Decisiones de Jürgen (2026-09-09, pasada de desbloqueo)

Preguntadas una a una antes de soltar la cola autónoma. **Mandan sobre lo escrito arriba.**

### Lo medido en producción antes de decidir (2026-09-09, MCP Supabase, proyecto `kefvaiymtgytemwbltlz`)

Producción **son dos cuentas y ninguna más, las dos de Jürgen**; cero datos de terceros:

| `profiles.id` | provider | tx | accounts | categories | budgets | grupos | `personal_claimed_at` | tipo |
|---|---|---|---|---|---|---|---|---|
| `1487d06a-1605-4afd-9412-434ac97c9f3e` | — | 0 | 0 | 0 | 0 | 2 | no | `groups_only` |
| `27751374-1225-482c-9e42-fedae5e02f98` | apple | 31 | 11 | 13 | 4 | 2 | **sí** | `complete` |

Totales: `split_groups` 2 · `group_members` 4 (los dos grupos tienen exactamente esas dos cuentas)
· `split_expenses` 9 · `split_shares` 22 · `split_settlements` 4 · `group_invites` 2 · `push_tokens` 3
· `auth.users` 2 (último `last_sign_in_at`: **2026-09-09**, o sea la sesión de device-QA viva).
Ninguna de las dos tiene `migrated_at`: **lo personal nació en la nube y no tiene copia en CloudKit**.

**`personal_claimed_at` clasifica correctamente las dos**, así que el «medir en staging qué tabla/contador
lo prueba» del alcance §1 ya está contestado, y medido contra prod: esa es la señal.

### Las decisiones

- **Se añade columna `kind` explícita** (`text not null default 'groups_only'`, check
  `in ('complete','groups_only')`), aunque `personal_claimed_at` ya dé la misma señal. Queda sabido y
  aceptado el riesgo de dos verdades sobre lo mismo: **quien toque una ruta que cambie el tipo de cuenta
  tiene que mantener las dos coherentes**, y los tests deben cubrir esa coherencia.
- **El campo del wire se llama `kind`** (`GET /account/exists` → `{ exists, kind? }`). Sin cambios en el
  ADR ni en los tickets 3, 8, 9 y 10.
- **`kind` ausente ⇒ `groups_only`, PERO con corrección al refrescar.** El cliente no bloquea el sign-in
  (un gateway caído dejaría a la gente fuera) y no se queda en el modo equivocado: en cuanto una llamada
  posterior devuelva `kind`, la sesión se corrige sola y lo personal aparece. Hay que implementar esa
  corrección, no solo el default.
- **El backfill se escribe igual** (`complete` si `personal_claimed_at is not null`), aunque tras el
  borrado no vaya a tocar ninguna fila en prod: sirve para staging y para cuando haya usuarios reales.

### FRESH START de producción — decisión explícita de Jürgen

**Antes de aplicar el esquema, la sesión que implemente este ticket borra producción entera**, incluidas
las **identidades de `auth.users`**. Es un borrado irreversible aprobado con los conteos de arriba
delante; no vuelvas a preguntar, pero tampoco lo amplíes.

- **Alcance:** todas las tablas de datos + `profiles` + las 2 filas de `auth.users`. Fresh start real: el
  siguiente sign-in con Apple/Google crea una cuenta nueva y ejercita el alta completa.
- **Se pierden a propósito:** 31 transacciones, 11 cuentas, 13 categorías, 4 presupuestos, los 2 grupos
  con sus 9 gastos / 22 shares / 4 liquidaciones, y las 2 invitaciones. **No hay copia en CloudKit.**
- **Orden:** respetar las FKs (hijos antes que padres; `profiles` antes que `auth.users`). Anotar en el PR
  los conteos **antes y después**, medidos, no estimados.
- **Consecuencia para Jürgen, avísasela en el PR:** su iPhone queda con una sesión apuntando a una cuenta
  que ya no existe. Tendrá que cerrar sesión o reinstalar, y **volver a crear los grupos de prueba** antes
  del device-QA de los tickets 5, 8, 9 y 10.
- **Staging NO se toca**: su corpus y sus usuarios de test sostienen los goldens del gateway, que son
  justo lo que valida esta migración.
