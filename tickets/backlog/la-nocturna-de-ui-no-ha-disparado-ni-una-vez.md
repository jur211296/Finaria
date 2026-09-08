---
id: la-nocturna-de-ui-no-ha-disparado-ni-una-vez
status: backlog
priority: medium
area: ci
created: 2026-09-08
updated: 2026-09-08
source: medido al verificar en producción el cierre de `el-job-de-tests-del-ci-no-tiene-timeout`
---

# La nocturna de UI está configurada y verificada, pero el `cron` no ha disparado ni una vez

## Qué se midió (2026-09-08, 09:44 UTC)

`el-job-de-tests-del-ci-no-tiene-timeout` mudó la suite de UI a una corrida nocturna
(`cron: '17 8 * * *'`, commit `6a9df989`, en `2.1` desde el 2026-09-08 00:05 UTC). La primera
ventana posible era **hoy a las 08:17 UTC**, con el workflow ya 8 h en la rama por defecto.

**No disparó.** Y no es que fallara: es que no existe.

```
gh run list --workflow qa.yml --limit 100 --json event --jq '[.[].event]|group_by(.)|map({ev:.[0],n:length})'
→ [{"ev":"pull_request","n":48},{"ev":"push","n":51},{"ev":"workflow_dispatch","n":1}]
```

**Cero runs con `event: schedule`** en la ventana de 100 runs (que llega hasta el 2026-09-06).

## Lo que ya está descartado, medido

Las cuatro causas habituales no son:

| Causa candidata | Medición | Veredicto |
|---|---|---|
| El workflow no está en la rama por defecto | `default_branch` = `2.1`; el commit está en `origin/2.1` | descartada |
| El workflow está deshabilitado | `gh api .../actions/workflows` → `state: active` | descartada |
| Apagado por inactividad (repo público, 60 días) | `pushed_at` = hoy; el estado sería `disabled_inactivity`, no `active` | descartada |
| El `cron` es inválido | `17 8 * * *`, cinco campos; actionlint 1.7.12 en verde sobre el fichero | descartada |

Queda la explicación aburrida y probable: **GitHub retrasa y a veces omite la ventana**, sobre todo
la primera tras añadir un `schedule`. Está documentado ("the `schedule` event can be delayed during
periods of high load"). El minuto 17 ya se eligió para esquivar la congestión de la hora en punto.

**Una sola ventana perdida no prueba que esté roto.** Por eso esto es un ticket y no una alarma.

## Que la nocturna FUNCIONA ya está probado — no es lo que se duda aquí

El `workflow_dispatch` corre exactamente lo mismo que la nocturna, y corrió:

| run | evento | rama | duración | resultado |
|---|---|---|---|---|
| `34173188063` | `workflow_dispatch` | `2.1` | **89,7 min** | success |

Es decir: el contenido de la nocturna está verificado de punta a punta, con la UI dentro y sobre la
rama correcta. Lo que no está verificado es **que el reloj la despierte sola**.

La distinción importa porque es justo el modo de fallo que el YAML avisa que hay que vigilar: una
corrida programada que desaparece sin que nadie la toque no rompe nada, no pone nada en rojo y no
avisa. Simplemente deja de haber cobertura de UI, en silencio, y nadie se entera hasta que un bug de
UI llega a producción.

## Cómo se cierra

Comprobar tras la ventana del **2026-09-09 08:17 UTC**:

```bash
gh run list --workflow qa.yml --limit 60 --json event,createdAt,conclusion \
  --jq '.[] | select(.event=="schedule")'
```

- **Sale al menos un run** → era el retraso de la primera ventana. Cerrar el ticket anotando el
  retraso real medido, que es el dato útil para la próxima vez.
- **Sigue vacío tras dos ventanas** → ya no es retraso. Siguiente paso: `gh workflow enable qa.yml`
  (barato, idempotente, y descarta un apagado que la API no esté reflejando), y si tampoco, mover la
  nocturna a un disparador que no dependa del cron de Actions.

## Distinto de

- `el-job-de-tests-del-ci-no-tiene-timeout` (done) — puso los topes y mudó la UI. Los topes están
  verificados en producción; esto es el cabo que aquel no podía comprobar porque el cron aún no había
  tenido ninguna ventana.
- `ci-warns-but-does-not-block` — va del `continue-on-error`, no del disparo.

## Acceptance Criteria

- [ ] Queda medido si el `schedule` dispara solo, sobre al menos dos ventanas.
- [ ] Si no dispara, la suite completa de UI vuelve a tener una corrida diaria efectiva por algún
      medio, y queda escrito cuál.
