---
updated: 2026-09-10
tags: [now, punto-de-retomada]
---

# NOW — 2026-09-10 (Lima)

**Rama** `2.1` — Merge #131: el **paso 3** del rediseño de sesiones. TestFlight build **13** (CPV 13).
**Subida Yala (TF/store) = solo Mini.**

## Esta sesión (paso 3: el sign-in ya rutea, y el Worker está desplegado)

**Al entrar con Google o Apple, Yala pregunta al backend qué hay detrás de esa cuenta y te lleva donde
toca.** Ya no adopta como completa a quien solo tiene grupos, ni trata como solo-grupos a quien tiene años
de finanzas ahí. «No encontramos una cuenta» tiene salida al alta, y asociar a tu Yala privado una cuenta
que ya lleva Yala completo se **bloquea sin escribir nada**.

**El Worker está desplegado en los dos entornos** (prod `034e1074`, staging `53e181d4`), con la base
verificada antes en cada uno — el orden importa: sin la columna, cada sign-in da 502. **`kind` ya viaja.**
Dos datos del deploy: staging llevaba **sin desplegar desde el 12-ago** y subió 12 commits de golpe, entre
ellos el fix de los goldens de Grupos que nunca se había desplegado; y el deploy de prod **no apagó** la
elección nube del Welcome, que es la primera prueba real de lo que protegía el paso 1.

**La review adversarial cazó nueve defectos** de la primera versión, dos graves: el bloqueo se deshacía
solo —tres de sus cuatro salidas dejaban viva la cuenta rechazada— y el eje de sesión confundía «móvil
limpio» con «ya está en la nube», así que a alguien ya adoptado le montaba la migración de su propia
cuenta. Los nueve y sus cinco premisas falsas, en el ticket.

## Tu cola

1. **Cierra sesión en el iPhone y recrea los grupos de prueba.** Es lo ÚNICO que falta para el device-QA
   del paso 3: el móvil apunta a la cuenta que borró el fresh start y cada llamada da 409/502.
2. **Device-QA del paso 3** — los cuatro recorridos del ticket. Sal del bloqueo **por swipe y por
   «Entendido»**, no solo por el botón; y en el recorrido 1 **fuerza el cierre de la app** antes de darlo
   por bueno. Más los device-QA de los pasos 4, 5, 8, 9 y 10.
3. **Física, la de siempre**: push APNs real (4), RPC de producción (3), sign-in real SIWA/Google (6),
   Apple Pay y carreras de red (4).
4. **De FX quedan cuatro** · **tres veredictos de QA caducos** · **el build 13 no llega al grupo externo**
   hasta pasar beta review.
5. **DMARC el 15-sep** · **cobertura de UI el 22-sep**. Esperan al calendario.

## Siguiente

**El paso 4** (`welcome-private-fresh-start-skips-icloud-check`). Pasos 0-3 cerrados; el 11 sigue vacante
a propósito. **El board: 161 en backlog, 48 en qa** (267 = 267 contra disco).

## Bloqueo

**Un bug vivo medido hoy** (`settings-migrate-to-cloud-adopts-silently-instead-of-migrating`, **high**):
«Ajustes → migrar a la nube» sobre una cuenta que ya tiene datos **no migra: adopta en silencio**, y te
cobra dos confirmaciones destructivas antes. Tus datos locales se quedan donde están, sin aviso.

**Los goldens de grupos** (`corpus-de-test-de-staging-crece-sin-limite`, **high**): seguían sin dar señal
por timeout, con 702 grupos de un usuario de test. **Dato nuevo:** el deploy de staging subió `f84620b5`
—el fix del canon viejo, sin desplegar desde el 8-sep— así que **un rojo anterior a hoy puede no valer**.
Re-medir antes de perseguirlo.

**Una decisión tuya** (`reverse-cutover-cerrado-para-cuentas-born-cloud`, **high**): la degradación a
solo-grupos funciona, pero su puerta exige `migrated_at` y ninguna cuenta born-cloud lo tiene — tras el
fresh start, el 100 % de producción.

**Sigue en pie:** la política de privacidad y los términos **bloquean la publicación** del rediseño. Y las
decisiones tuyas de antes: el filtro de naturaleza, los worktrees sin candado anti-atribución, ¿se ataca
ya el chat caído?, y si `fab-appears-without-animation` sube de `low`. **Sin ticket, medido el 9-sep:** un
CSV exportado antes de convertir una cuenta ya no se importa a ella y aborta el fichero entero.
