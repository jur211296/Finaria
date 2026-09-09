---
id: ci-avisador-de-rojos-advisory-tiene-la-clave-mal
status: in-progress
priority: high
area: "ci, observabilidad"
created: 2026-09-08
updated: 2026-09-09
source: run 34309857537 del PR #110 (2026-09-08)
---

# El avisador de rojos advisory del CI no puede avisar: `Invalid API key`

## Qué pasa

El job `tests` de `.github/workflows/qa.yml` corre sus pasos de test como **advisory**
(`continue-on-error`), y para que un rojo no pase inadvertido tiene un paso final —«Avisar a Grok si
algun paso advisory fallo»— que manda el aviso al webhook. Ese paso **no puede mandar nada**:

```
CI de jur211296/Yala (110/merge): hay pasos de test en ROJO que el run marca como verde.
Pasos en rojo:
- Unit tests (pure-logic)
##[error]Nadie se ha enterado de que hay tests en rojo.
{"code":"error","message":"Invalid API key"}
##[error]Process completed with exit code 1.
```

El `SENDER_KEY` del secreto del repo no es válido para el webhook. El paso lo detecta y sale con
`exit 1`, que es lo correcto por su parte —prefiere romper el job antes que callar—, pero el efecto
neto es que **el aviso no llega a nadie** y el job entero se pone rojo por un fallo de credencial, no
por los tests.

## Medido el 2026-09-09 en el PR #118: además de no avisar, **BLOQUEA EL MERGE**

Dos corridas del mismo PR, con la misma credencial mala, y el resultado opuesto:

| Run | Pasos advisory | Paso «Avisar a Grok» | Job `tests` | El PR |
|---|---|---|---|---|
| `34405910548` | uno en ROJO | `Invalid API key` → `exit 1` | **fail** (28m20s) | no se puede mergear\* |
| `34413108303` | todos verdes | `success` (no llega al `curl`) | **pass** (25m18s) | `CLEAN`, mergeado |

\* **Matizado el 2026-09-09, midiendo:** `2.1` no tiene protección de rama ni rulesets
(`branches/2.1/protection` → 404, `rulesets` → `[]`), así que GitHub **no bloquea** ningún merge
por un check en rojo. Lo que paró el #118 fue nuestra propia `/cerrar-total`, cuyo paso 0 para si
`mergeStateStatus` no está limpio — y con checks rojos no requeridos ese estado es `UNSTABLE`, que
significa «mergeable con checks fallando», no «bloqueado». El efecto es real; la causa es de
proceso, no de GitHub. Ticket propio: `cerrar-total-para-ante-un-check-rojo-que-no-bloquea`.

⇒ El daño no es solo «el aviso no llega». **El paso anula el diseño `continue-on-error` de sus
propios pasos**: la razón de que los tests sean advisory es que un flaky conocido no frene el
trabajo, y hoy basta uno para que el avisador ponga el job en rojo y el PR deje de ser mergeable.
El repo pasa a comportarse como si los tests fueran bloqueantes, pero solo cuando fallan — que es
justo el caso en el que se quería lo contrario.

Y hay una segunda mitad, para quien lo arregle: **el `exit 1` está bien puesto y no hay que
quitarlo**. Preferir romper el job antes que callar es la decisión correcta; lo que hay que
arreglar es la credencial. Cambiar el `exit 1` por un `exit 0` haría que un rojo advisory volviera
a pasar inadvertido, que es el bug que este paso existe para cerrar.

**Cómo reproducirlo sin esperar a un flaky:** cualquier PR con un test en rojo dentro de un paso
advisory. En el #118 fue una aserción que dependía de la divisa preferida de la máquina — verde en
local, roja en CI.

## Por qué es `high` pese a que «el CI ya avisó»

**Porque nunca se había ejercitado y nadie lo sabía.** Medido sobre los 12 runs anteriores del
workflow: todos `success`, porque el paso de avisar solo se ejecuta cuando hay algo que avisar. El run
`34309857537` fue el primero con un paso advisory en rojo, y ahí se descubrió que la única red que
cubre a los pasos advisory llevaba puesta una llave que no abre.

Es el patrón que este repo ya pagó una vez con el guardián nocturno, que estuvo **un mes** entregando
partes a un webhook que devolvía 404. Un canal que nadie mira se muere en silencio; uno que solo se
usa en caso de incendio, también — y encima no se nota hasta el incendio.

## El daño concreto que deja mientras siga así

El diagnóstico apunta al sitio equivocado. Un `tests: fail` en un PR **no distingue** hoy entre:

- tests de verdad en rojo (lo que quieres mirar), y
- tests en verde con la credencial del avisador rota (ruido).

En este run eran **las dos cosas a la vez**: había un rojo advisory real —un source-scan de conteo— y
además la credencial estaba mal. Quien vea solo el rojo del job puede concluir «es el avisador otra
vez» y mergear encima de un test que sí fallaba, que es exactamente lo que este mecanismo existe para
impedir.

## Criterio de hecho (AC)

- [ ] Rotar `SENDER_KEY` (y comprobar `WEBHOOK_URL`) en los secretos del repo, contra el webhook que
      esté vivo hoy. **Generar y persistir en el mismo gesto**: la credencial no puede quedarse solo en
      la pantalla de quien la crea.
- [ ] **Verificar el camino entero, no la rotación.** Un `curl` de prueba contra el webhook con la
      clave nueva **desde el runner**, no desde el Mac: el secreto que falla es el del repo, y probarlo
      en local no demuestra nada.
- [ ] Un paso que ejercite el avisador **aunque no haya rojos** —un ping periódico, o el propio
      guardián nocturno— para que la próxima vez no se descubra en el incendio. Sin esto el AC anterior
      caduca sin avisar.
- [ ] Decidir si `exit 1` del avisador debe seguir tumbando el job. Hoy mezcla dos señales muy
      distintas en un solo `tests: fail`; separarlas (por ejemplo, un check propio para el aviso) haría
      el rojo legible de un vistazo.


---

## Cerrado el 2026-09-09 — PR #123

### Lo que apareció al medir, y que el ticket no sabía

**No era un workflow, eran tres.** `qa.yml`, `avisar-grok-push-principal.yml` y
`nocturna-vigilante.yml` comparten el mismo par de secretos y tenían el mismo bloque
«componer + `curl` + mirar el HTTP» **triplicado**, con tres tratamientos de error distintos.
Cuando la routine se rehizo cayeron los tres a la vez, y como cada uno decidía por su cuenta qué
hacer con el fallo, el daño fue distinto en cada sitio.

**El ejercicio periódico que pide el AC nº3 ya existía.** `avisar-grok-push-principal.yml` POSTea
al mismo webhook en cada push a `2.1`. Medido sobre sus 100 últimos runs: **37 seguidos en rojo**
desde el 2026-09-08T19:09Z, los 63 anteriores en verde. Eso data el momento exacto en que la
credencial dejó de valer, y dice algo peor que «faltaba un ping»: **lo había, llevaba día y medio
cantando el fallo, y nadie lo miraba.** Un canal que solo se usa en el incendio se muere en
silencio; uno que canta en un check que nadie abre, también.

**De los 3 rojos de `qa.yml` en las 40 últimas corridas, los TRES eran del avisador — y dos
tapaban señal real:**

| Run | Lo que tapaba |
|---|---|
| `34354119553` (nocturna) | La suite de UI en ROJO: `Executed 145 tests, with 12 failures` |
| `34333956615` (push a `2.1`) | `Build for testing` roto: el runner no tenía el simulador |
| `34405910548` (PR #118) | Un rojo advisory real (el del ticket) |

Los dos primeros no llegaron a nadie. Tickets propios:
`nocturna-del-9-sep-dejo-cuatro-xcuitest-en-rojo` (los cuatro casos, identificados) y
`ci-runner-se-queda-sin-simuladores-y-tumba-build-for-testing` (ya existía).

### AC

- [x] **Credencial viva.** Jürgen rotó los dos secretos el 2026-09-09T23:25Z. Verificada, no
      supuesta: HTTP **200** contra el webhook real desde el runner (run `34417746163`).
- [x] **Camino entero desde el runner, no `curl` local.** Es lo que hace el ping nuevo, y por eso
      se dispara también al tocar el propio avisador: `workflow_dispatch` solo se lanza desde la
      rama por defecto, así que en una rama de encargo no serviría y el cambio no se podría
      verificar antes de mergearlo.
- [x] **Un ejercicio que no espere al incendio.** `ping-avisador.yml`: diario, a mano, y al tocar
      el avisador. No es ruido: por ese webhook ya viajan ~30 avisos al día del workflow de push
      (medido), así que el ping es un 3 % más de tráfico.
- [x] **Decidido el `exit 1`** (Jürgen, 2026-09-09): **check propio + canal de respaldo**. El
      aviso sale del job `tests` a un job `aviso` que lee los `outcome` por outputs. Y el `exit 1`
      **no se quita**, como pedía el ticket: lo que cambia es que ahora hay dos formas de no callar
      antes de tener que romper. Si el webhook no responde, el aviso queda escrito en un issue del
      repo (etiqueta `aviso-ci`); solo cuando no queda **ningún** canal se pone en rojo.

### Cómo se verificó el respaldo, que es la parte nueva

Con control positivo, no por inspección:

- Canal caído a propósito (URL a un host inexistente) → **abrió el issue #122**. Eso mide de paso
  que `issues: write` funciona pese a que el permiso por defecto de Actions en este repo es `read`.
- Segundo fallo seguido → **comentó en #122 en vez de abrir otro**. Sin esa agrupación, el canal
  muerto de estos dos días habría dejado 37 issues y el respaldo se ahogaría en su propio ruido,
  que es el final del canal que vino a sustituir.
- #122 quedó cerrado con la explicación. No hay incidencia real detrás.

La lógica del aviso se verificó **en local**, extrayendo el `run:` del YAML: matriz de 9
escenarios (PR verde, nocturna verde, cada paso en rojo, build roto, job cancelado, UI que tocaba
y no corrió, dos rojos a la vez) más dos mutantes de control que la matriz caza.

### Lo que hay que saber para tocar esto

`actionlint` **no mira** `.github/actions/*/action.yml` — linta solo `workflows/`. Su primer verde
sobre la action nueva era un verde sobre **cero ficheros**, y el YAML estaba roto. Sí valida los
`with:` de una action local contra sus `inputs:`. Recogido en `docs/aprendizajes-tecnicos.md`.
