---
id: claim-promotion-lost-response-blocks-the-retry
status: backlog
priority: medium
area: "modo-nube, groups"
created: 2026-09-11
source: "review adversarial del paso 8 del rediseño de sesiones (`full-mode-activation-must-ask-where-personal-data-lives`)"
---

# Si se pierde la respuesta de la promoción, «Reintentar» bloquea la activación a la nube

## El síntoma, en lenguaje de usuario

Uso Yala solo para grupos y activo Yala completo → «Tu cuenta en la nube». Hago el onboarding, contesto la
pregunta del historial y sale «Activando tu cuenta…». Se corta la red justo ahí: «No hemos podido activar tu
cuenta». Toco «Reintentar» y me dice «Tu cuenta ya tiene finanzas personales». No las tiene: la promoción
llegó al servidor y la respuesta no llegó al teléfono. Desde aquí ya no puedo activar la nube.

## Por qué pasa (medido el 2026-09-11)

- La promoción es `POST /account/claim` (`BornCloudSignUpService.signUp`). Con la fila ligera de grupos
  (`personal_claimed_at` nulo) contesta `created` y la marca como completa; con esa fecha ya puesta contesta
  `existing_stable` (`qa/cloud/g15_01_account_kind.sql`).
- Un fallo de red DESPUÉS de que el servidor confirme se ve en el cliente como `.transient` → «Reintentar».
  El reintento encuentra la fecha puesta → `existing_stable` → la activación lo trata como una cuenta que ya
  tiene lo personal (`FullModeActivationFlowLogic.promotionStep`) y bloquea sin escribir nada.
- Lo mismo deja un kill entre la promoción y la primera escritura local, que son dos llamadas síncronas
  seguidas: la cuenta queda completa en el servidor sin nada personal detrás.

Es seguro —no se escribe ni se pierde nada—, pero la única salida que le queda (cerrar sesión y volver a
entrar) le lleva a una cuenta completa VACÍA en la nube.

## Alcance

- Distinguir «la acabo de promocionar yo y no tiene nada» de «ya tenía lo personal»: que el claim diga si la
  cuenta tiene filas personales, o un token de idempotencia por intento de activación.
- Con esa señal, el reintento sigue con el commit (almacenamiento nube → persistir [P]) en vez de bloquear.

## Criterios de aceptación

- [ ] Promoción confirmada en el servidor + respuesta perdida → «Reintentar» termina la activación.
- [ ] Una cuenta que de verdad tiene lo personal reclamado (desde otro dispositivo) sigue bloqueando sin
      escribir nada.
