---
id: flows-atlas-predates-session-redesign
status: backlog
priority: low
area: "docs, modo-nube, onboarding"
created: 2026-09-10
updated: 2026-09-10
source: "review adversarial del paso 7 del rediseño de sesiones (`onboarding-purpose-drops-groups-card`)"
---

# El Atlas de flujos de Modo Nube describe pantallas que el rediseño de sesiones ya retiró

## Qué pasa

`docs/flows/modo-nube/` (el Atlas: storyboard por persona, `index.html` + `data/*.js` + `check.mjs`)
está anclado a **HEAD `5bbb5690` del 2026-08-12**, y su README lo dice: si el código se mueve, lo que
caduca es el Atlas. El rediseño de sesiones (ADR 2026-09-09 «Sesiones — dos ejes») lo está moviendo
paso a paso, y el Atlas sigue contando lo de antes.

Medido el 2026-09-10, con el paso 7 aplicado:

- **`node docs/flows/modo-nube/check.mjs` pasa de 4 a 13 fallos.** Los 9 nuevos son la comprobación de
  l10n: `data/l10n.js` cita 7 keys que el paso 7 borró de los 16 `.strings` (la card «Dividir gastos con
  amigos», sus textos de moneda y resumen, y el aviso de iCloud de la card), en los nodos
  `onboarding-purpose`, `onboarding-muro`, `onboarding-groupsonly` y `visita-privado-onboarding`. Los 4
  anteriores (valores que ya no casan) venían de antes.
- **Tres paneles describen una card que ya no existe** (`onboarding-muro`, `onboarding-groupsonly` y la
  card del panel `onboarding-purpose`), y el recorrido **R4 «Solo quiero grupos»** los incluye.
  `data/nodes.js`, `flows.js` y `f2.js` los citan con `OnboardingGroupsOnlyGuardUITests` y
  `OnboardingGroupsPurposeGateLogic`, que tampoco existen ya.
- Y lo que viene detrás es más grande: los recorridos **R10 «Estoy de visita»** y **R11 «El dueño
  recupera su móvil»** son la sesión secundaria (M1), que el mismo ADR retira en el ticket 12.

`check.mjs` no lo corre ni el CI ni el gate, así que nada bloquea. Pero el Atlas se consulta creyendo que
cuenta la app de hoy.

## Por qué no se arregló en el paso 7

Editar a mano cuatro nodos dejaría el Atlas mitad anclado a `5bbb5690` y mitad al 2026-09-10, que es
peor que un Atlas entero y fechado. Y el paso 7 es uno de trece: re-anclarlo ahora obligaría a
re-anclarlo otra vez tras el 8, el 9, el 10 y el 12.

## Lo que hay que decidir (Jürgen)

- **Re-anclarlo entero cuando termine el rediseño** (tras el ticket 12), con capturas nuevas; o
- **Retirarlo** si el storyboard ya no se usa, y quedarse con la matriz del rediseño
  (`docs/sessions/2026-09-09-matriz-escenarios-sesiones.md`) como mapa de escenarios.

## Criterio de aceptación

- [ ] Decisión tomada y escrita aquí.
- [ ] Si se re-ancla: `node docs/flows/modo-nube/check.mjs` en `RESULT: OK` contra el árbol del
      re-anclaje, y la cabecera del Atlas con la fecha nueva.
