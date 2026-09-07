---
name: la-frontera-de-la-visita
description: Qué queda abierto en la frontera entre la visita y el dueño del teléfono tras cerrar la rama privada del Welcome (7-sep). El código está hecho; falta device-QA de dos cuentas y dos decisiones de Jürgen sobre qué más cruza esa frontera.
metadata:
  type: project
---

**Estado al 2026-09-07.** La rama privada del Welcome («Es mi primera vez → privacidad total») ya
avisa en sesión secundaria y el onboarding en visita dejó de prometer categorías que no crea —
PR #86, mergeado. Lo que sigue vivo:

**Espera device-QA (tuyo, no se destraba solo).** El seam `-uitest-secondary-session` enciende el
descriptor pero **no monta** un store secundario, así que lo comprobado en simulador es la decisión y
la pantalla, no el e2e. Con dos cuentas reales falta ver: los datos de la visita en SU store, su saldo
inicial registrado (el arreglo nuevo), y que el copy quepa en alemán y neerlandés — solo se vio en
español. Ticket en `tickets/qa/welcome-privacy-branch-has-no-secondary-door.md`.

**Espera decisión de Jürgen (2, y las dos son key por key, no un barrido):**

- `secondary-onboarding-still-crosses-owner-domain` — el prellenado del onboarding **lee** del dueño
  (nombre, divisa, `expensesOnlyMode`) y `notificationsSeeded` **escribe** en él. La divisa heredada
  probablemente sí se quiere; el nombre y el modo, no — y `expensesOnlyMode` heredado **apaga la rama
  que crea la subcategoría de saldo** que el PR #86 acaba de encender. Las notificaciones de la visita
  sonando en un móvil prestado son decisión de producto, no limpieza.
- `secondary-visit-data-lost-on-signout-unannounced` — el wipe de salida borra lo que la visita
  apuntó. Es correcto; qué se le cuenta y cuándo son cuatro salidas con contrapartidas.

**Y dos que no necesitan decisión, solo trabajo:** `welcome-beacon-reads-owner-icloud-in-secondary`
(el faro lee el iCloud del DUEÑO y decide antes que nada en «Soy nuevo», así que en el móvil de un
usuario de nube la pantalla nueva **no se ve**) y `welcome-private-card-promises-icloud-in-visit`
(low, hasta que el percent del sub-chooser suba de 0).

**El patrón que gobierna esta familia entera, y que conviene llevar puesto al retomarla:** el guard
que falta suele estar **medio puesto**. `clearResidualPreferencesForFreshStart` tenía su mitad iKV
protegida, con un comentario que nombra la sesión secundaria, y la mitad local en `.standard` crudo.
La pregunta no es «¿está protegido este fichero?» sino «¿están protegidas las dos mitades?». El caso
completo está en `docs/aprendizajes-tecnicos.md`.

Relacionado: [[identidad-del-joiner-en-grupos]] · [[archivado-no-acepta-entradas]] ·
[[salir-del-grupo-espera-decision]] — la misma épica, otros frentes.
