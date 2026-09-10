---
id: wrangler-prod-onboarding-choice-percent-drift
status: backlog
priority: high
area: "gateway, cloud"
created: 2026-09-09
source: "medido el 2026-09-09: curl al /config de producción vs gateway/wrangler.toml"
---

# El repo dice que la elección nube del onboarding está apagada en producción, y producción la sirve al 100 %: el próximo deploy la apaga

## Qué pasa

Jürgen subió la elección born-cloud a producción en un PR que después se borró. El gateway de
producción la sirve; el repo no lo sabe.

Medido el 2026-09-09:

```
curl https://yala-gateway-production.misty-surf-6866.workers.dev/config
{"v":1,"flags":{"cloudModeRolloutPercent":100,"cloudOnboardingChoiceRolloutPercent":100,
 "groupsBackendRolloutPercent":100,"secondarySessionRolloutPercent":0},"forceUpdate":{"minSupportedBuild":0}}
```

```
gateway/wrangler.toml:130   CLOUD_MODE_ROLLOUT_PERCENT = "100"            # [env.production.vars]
gateway/wrangler.toml:132   CLOUD_ONBOARDING_CHOICE_ROLLOUT_PERCENT = "0"  # ← producción sirve 100
gateway/wrangler.toml:51-52 (staging: 100 / 100)
```

`wrangler deploy --env production` desde el repo escribe las `vars` del `.toml` ⇒ **el siguiente deploy
del gateway, por cualquier otro motivo, apaga la card «Tu cuenta en la nube» del Welcome** en todo el
parque, sin que nadie lo haya decidido.

## Por qué importa

Es el hermano de `storage-row-gate-comment-says-rollout-zero` (allí era un comentario del cliente el
que describía prod al revés; aquí es el fichero que **se despliega**). Y los tickets y docs que citan
«percent 0 en producción» para la elección nube (`WelcomeAccountChoiceLogic.swift` cabecera,
`CloudRemoteConfig.swift` cabecera, varios tickets) describen un estado que ya no es.

## Lo que hay que hacer

- [ ] `gateway/wrangler.toml:132` → `"100"`, con el comentario de fecha como ya tiene `:125-129` para
      `CLOUD_MODE`.
- [ ] Corregir los comentarios del cliente que afirman «0 en producción» para la elección
      (`WelcomeAccountChoiceLogic.swift`, `CloudRemoteConfig.swift`, `WelcomeFlowContainer.swift`
      donde diga «percent remoto en 0»). Grep: `ONBOARDING_CHOICE_ROLLOUT_PERCENT` y «percent remoto».
- [ ] Un test del gateway (`gateway/test/config.test.ts`) que fije los cuatro percents de producción
      leyendo el `.toml`, para que un cambio de rollout sea un diff visible y no un deploy silencioso.
- [ ] Antes de mergear: `curl` al `/config` de prod otra vez y anotar el valor en el PR.

## Fuera de alcance

Decidir el rollout. Este ticket alinea el repo con lo que Jürgen ya decidió y desplegó.

## Decisiones de Jürgen (2026-09-09, pasada de desbloqueo)

Preguntadas una a una antes de soltar la cola autónoma. **Mandan sobre cualquier interpretación del ADR
o de este ticket**; si algo de arriba las contradice, ganan éstas.

- **El test fija solo los TRES percents vivos**: `cloudModeRolloutPercent`,
  `cloudOnboardingChoiceRolloutPercent` y `groupsBackendRolloutPercent`.
  `secondarySessionRolloutPercent` se deja **fuera** a propósito: el ticket 12 retira M1 entera y no
  queremos tocar este test dos veces. Coste aceptado: durante los pasos 1-11 nadie vigila ese percent.
- **El test NO toca la red.** Parsea `gateway/wrangler.toml` y compara contra los valores esperados.
  Determinista y sin credenciales en CI. Queda sabido que así no se detecta un cambio hecho a mano
  desde el dashboard de Cloudflare.
- **Staging no se toca.** `SECONDARY_SESSION_ROLLOUT_PERCENT = "100"` en `[env.staging.vars]`
  (línea 56 al 2026-09-09) **se queda como está**: es objeto del ticket 12, no de éste.
- **Sí se despliega tras mergear**: `wrangler deploy --env production` y `curl` de confirmación al
  `/config`, para dejar repo y producción idénticos y comprobados. El valor medido antes y después va
  anotado en el PR.
