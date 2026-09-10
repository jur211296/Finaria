---
id: borncloud-consent-epoch-written-before-the-guard-decides
status: backlog
priority: medium
area: "modo-nube, onboarding, gdpr"
created: 2026-09-10
source: "lente adversarial durante `cloud-sign-in-discovers-account-kind` (bloque [I])"
---

# El alta en la nube escribe el registro de consentimiento antes de saber si va a poder entrar

## El problema

El alta born-cloud escribe el epoch del consentimiento **al aceptarlo**, y eso es correcto bajo su propia
premisa: «su ruta ya se conoce ahí y su claim la VERIFICA» (docblock de `WelcomeCloudSignInView`, M0). Pero
el claim puede devolver `existing_stable` —la cuenta ya existía— y entonces el flujo se va por
`.continueAsReturningUser` → `runSignInFlow` → guard cross-cuenta, que puede terminar en
`.blockedForeignData` o en la entrada secundaria: **los dos desenlaces para los que M0 declaró
explícitamente que la re-entrada NO debe escribir el epoch**, porque cae en el iCloud-KV del DUEÑO del
dispositivo y no en el de quien lo aceptó.

## Cómo se llega

1. Welcome → card «nube» de «Soy nuevo» (o, desde el bloque [I], «Ya tengo cuenta» → «No hay cuenta» → el
   botón que lleva al alta).
2. Aceptar el consentimiento ⇒ **el epoch se escribe ya**.
3. Firmar con una cuenta que **sí** existe.
4. El claim contesta `existing_stable` ⇒ re-entrada ⇒ guard cross-cuenta.
5. Con corpus de otra persona en el dispositivo: `.blockedForeignData`. El epoch se quedó escrito.

## Es PREEXISTENTE, y el bloque [I] ensancha la vía

El paso 3 no lo introdujo: con `entry == .bornCloud` el recorrido es el mismo desde que existe A5. Lo que
[I] añade es una segunda puerta hacia el alta —el botón del `.notFound`— así que llega más gente al paso 2.
Se registra aquí en vez de arreglarse ahí porque la corrección toca la tabla de M0
(`CloudConsentRegistrationLogic`), que es la que decide dónde se escribe el epoch en cada ruta, y merece su
propio análisis con los tres desenlaces del claim delante.

## Lo que se espera

Que el epoch del alta se escriba en un punto donde su ruta ya esté **verificada**, como ya hace la
re-entrada, o que el camino `existing_stable` → guard → bloqueo lo retire. La tabla de M0 es el sitio.

## Criterios de aceptación

- [ ] Un alta cuyo claim devuelve `existing_stable` y termina en `.blockedForeignData` **no** deja epoch en
      el dominio del dueño.
- [ ] El alta que termina bien conserva su epoch con su T0 original (no el `now()` del final).
- [ ] `CloudConsentRegistrationTests` cubre el desenlace nuevo, con su control positivo.
