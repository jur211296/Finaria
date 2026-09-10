---
id: retire-guest-vocabulary-for-session-terms
status: backlog
priority: low
area: "docs, l10n"
created: 2026-09-09
source: "ADR 2026-09-09 «Sesiones — dos ejes» §1"
---

# «Cuenta invitada», «visita» y «sesión secundaria» se retiran del vocabulario: hay sesión privada y sesión en la nube

## Qué pasa

Tres nombres para la misma cosa, y ninguno describe lo que es: «cuenta invitada» / «visita» / «sesión
secundaria» = una sesión en la nube en un móvil cuya sesión privada es de otra persona. El ADR fija
dos términos —**sesión privada** (dispositivo + iCloud privado) y **sesión en la nube** (cuenta
Google/Apple, completa o solo grupos)— y retira los otros tres.

## Lo medido (2026-09-09)

- En textos de usuario casi no vive: **2 de 3.719** strings ES contienen «invitad»
  (`welcome.groups.secondaryTitle` «Aquí estás como invitado», `welcome.groups.secondaryBody`).
- Vive en código, comentarios, `.claude/rules/`, `docs/` y tickets. Es una decisión de glosario, no un
  barrido: los identificadores se retiran con el código en `shell-derives-from-two-session-axes`.
- Sobre el nombre: Jürgen propuso «sesión pública»; Frank propuso «sesión en la nube» («pública» en una
  app de finanzas se lee como «visible»). El ADR usa «en la nube»; **la palabra sigue siendo de Jürgen**
  y este ticket es donde se cierra.

## Lo que hay que hacer

- [ ] Jürgen ratifica el par de nombres («privada» / «en la nube» — o «pública»).
- [ ] `docs/glosario.md` (bloque manual): entradas para *sesión privada*, *sesión en la nube* (completa /
      solo grupos), *cuenta de grupos asociada*, *equipo*, *bloques [I] [P] [G]*, y una entrada
      histórica para *visita / secundaria / invitada (retirado)* que apunte al ADR.
- [ ] `.claude/rules/swiftdata-cloudkit.md` y las demás rules: sustituir el vocabulario donde describa
      comportamiento vigente; donde describa el M1 que se retira, marcarlo como histórico hasta que el
      código se vaya.
- [ ] Los dos strings ES y sus 15 hermanos se retiran cuando `WelcomeGroupsGateView` pierda la rama
      secundaria (ticket del barrido); hasta entonces no se tocan.
- [ ] Copy nuevo de todo el rediseño (chooser, cierres, «¿Dónde viven tus datos?») escrito con los dos
      términos y revisado contra `BRAND-VOICE.md`.

## Fuera de alcance

Renombrar identificadores de código por su cuenta: van con el código que los usa.
