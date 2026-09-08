---
name: verificar-backend-yala
description: Qué acceso real tengo al backend de Yala (MCP ve SOLO producción, no staging) y cómo verificar una migración SQL contra el motor real sin tocar nada — sandbox transaccional.
metadata:
  type: reference
---

**El acceso no es simétrico, y eso decide qué puedo verificar y qué no.** Medido el 2026-09-04.

| Recurso | ¿Tengo? | Por dónde |
|---|---|---|
| **BD de producción** (`kefvaiymtgytemwbltlz`) | **sí**, lectura y DDL | MCP Supabase |
| **BD de staging** (`fostjbbwstyuunmmefuk`) | **NO** | el conector MCP no la lista |
| Worker staging y producción | **sí**, deploy | `wrangler`, OAuth `admin@yala-app.pe`, `workers:write` |
| Usuarios de test de staging | sí, **con CONTRASEÑA** (no solo JWT) | `~/Secrets/yala-supabase-test/test-users.env` — trae `USER_A_PASS`/`USER_B_PASS` |
| Llaves de cifrado y push | sí | `~/Secrets/yala-groups-enc/` (`staging.key`, `staging-push-role.jwt`, y sus gemelos `prod`) |

**CORREGIDO el 2026-09-07: los goldens del gateway contra staging SÍ se pueden correr.** Esta ficha decía
«sólo JWT de usuario» y por eso ni lo intenté durante tres sesiones. `test-users.env` trae las CONTRASEÑAS
(`USER_A_PASS`, `USER_B_PASS`) y la llave de cifrado está en `~/Secrets/yala-groups-enc/staging.key`; con
las dos exportadas, `npx vitest run test/groups.goldens.test.ts` da **25/25 contra staging real** en ~5
min. Sin `GROUPS_ENC_KEY` el fichero entero falla en su `beforeAll` con los 25 casos en `skipped`, que
**parece** «no hay credenciales» y es solo una variable de entorno. Para la suite ENTERA hace falta una
tercera, o `push.fanout.test.ts` sale rojo por entorno y no por código:

    set -a; . ~/Secrets/yala-supabase-test/test-users.env; set +a
    export GROUPS_ENC_KEY="$(cat ~/Secrets/yala-groups-enc/staging.key)"
    export PUSH_ROLE_JWT="$(cat ~/Secrets/yala-groups-enc/staging-push-role.jwt)"

**Y `npx vitest` NO dispara `pretest`, así que NO sincroniza el manifest** (la copia del gateway está
gitignoreada). Corre `npm run sync:manifest` antes o medirás con el contrato de columnas viejo: eso dejó
dos goldens en rojo un día entero el 2026-09-07. Desde el 8-sep lo canta `test/manifest.sync.test.ts`.

**El número 25/25 es cierto pero FRÁGIL, y conviene saberlo antes de creerte un rojo:** un pull cuesta 5
peticiones por cada grupo del usuario —haya cambios o no— y el corpus de A/B sólo crece (530 y 678 el
8-sep, +20/+15 por corrida). El golden más ajustado consume el **55 %** de su timeout. Un rojo por
TIMEOUT sin línea de aserción probablemente no es código roto: es un test que va justo de tiempo. Ver
`corpus-de-test-de-staging-crece-sin-limite`.

Lo que sigue sin haber es **DDL de staging**, que es otra cosa: se pueden EJERCITAR los RPCs que ya están
allí, no APLICAR una migración nueva.

**La consecuencia incómoda: tengo DDL en producción y no en staging** — al revés de lo que pide el
orden habitual. No hay credencial de admin de staging en `~/Secrets/`, ni en el keychain, ni en el
entorno. Si un ticket dice «verificar en staging antes de producción», eso hoy **no se puede cumplir
por esa vía**, y hay que decirlo en vez de inventarlo.

## La vía que sí verifica: sandbox transaccional contra producción

Postgres tiene **DDL transaccional**, así que `create or replace function` dentro de `begin … rollback`
se revierte entero. Eso permite ejercitar una migración **contra el esquema y el motor reales** sin
dejar rastro — más fiel que staging, no menos.

Receta, con lo que costó afinarla:

1. **Comprueba primero que el rollback revierte de verdad** (que el cliente no esté en autocommit por
   statement): `begin; create table _probe(...); rollback;` y luego `to_regclass('_probe') is not null`
   → tiene que dar `false`. Sin este paso no arriesgues un `create or replace` sobre una función viva.
2. Dentro de la transacción: usuario sintético en `auth.users` (`profiles.id` es FK a esa tabla), las
   filas de dominio que haga falta, y `set local request.jwt.claims = '{"sub":"<uuid>"}'` — de ahí lee
   `auth.uid()`, sin necesidad de cambiar de rol.
3. Aplica la función nueva, ejercita los escenarios acumulando en una tabla temporal, haz un `select`
   final y `rollback`.
4. **Confirma que no quedó rastro**: el `md5(prosrc)` de la función vuelve al de antes y las filas
   sintéticas son cero.

**El control negativo es la mitad que da la prueba**, y es gratis: corre los mismos escenarios **sin**
el `create or replace`, o sea contra la función viva. Eso mide el bug en producción en vez de
inferirlo. En `rejoin-tap-renotifies-admins` fue lo que convirtió «el Worker no puede distinguir los
dos casos» en un hecho: el retorno del re-tap era **idéntico byte a byte** al del alta nueva.

## Lo que esto NO alcanza, y no hay que fingir que sí

El push que llega a un teléfono. `.claude/rules/gateway-attest.md` es explícito: un build de Xcode no
puede validar contra producción (el AAGUID de desarrollo da 401 por diseño), así que **quien escribe
el fix no puede ejercitarlo end-to-end**. Eso se documenta como pendiente del owner, no se declara
verificado.

Relacionado: [[mis-mediciones-fallan-por-el-filtro]] — su caso 9 es justo el error que esto evita
(«no consta en el repo» leído como «no está hecho»); aquí la regla se aplica en positivo.
