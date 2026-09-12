---
id: welcome-chooser-uitests-cannot-reach-the-chooser
status: backlog
priority: high
area: "testing, onboarding"
created: 2026-09-11
source: "medido el 2026-09-11 al correr el gate de `groups-invite-on-a-mirrored-store-crosses-data`; bisecado contra un worktree limpio de `2.1` (`1a9cbb83`)"
---

# Siete XCUITest del Welcome no pasan del Hero, y llevan así al menos desde el 11-sep

## Qué está roto

Siete casos, en dos suites, fallan **en `2.1` sin ningún cambio encima**:

| Suite | Caso | Lo que no aparece |
|---|---|---|
| `WelcomeChooserUITests` | `testExistingChooser_withCloudConfigured_showsThreeCards_andGoogleIntro` | la card de restaurar iCloud |
| `WelcomeChooserUITests` | `testNewChooser_withCloudConfigured_showsBothCards_andCloudCardOpensSignUp` | la card de privacidad total |
| `WelcomeChooserUITests` | `testNewBranch_withBeacon_routesToSignIn_andCreateAnotherOpensTheFullChooser` | el encaminamiento del faro |
| `WelcomeChooserUITests` | `testNewBranch_withUnknownBeaconMethod_saysTheGenericOrigin` | el origen genérico |
| `WelcomeChooserUITests` | `testGroupsOrganizer_createCardWalksToTheGroupForm` | la puerta del organizador |
| `SecondarySessionGateUITests` | `test_organizerGate_inSecondarySession_blocksWithItsOwnScreen` | la pantalla de la visita |
| `SecondarySessionGateUITests` | `test_organizerGate_withLocalCorpus_returnsToNeutralInsteadOfBlocking` | la vuelta al neutro |

**No son flaky y no son de nadie**: se reprodujeron dos veces seguidas en el árbol de trabajo y otras
dos en un **worktree limpio de `2.1`** (`git worktree add --detach … HEAD`, `1a9cbb83`), con los mismos
siete casos y los mismos mensajes. Es la bisección que los clasifica como preexistentes.

## Lo único que ya está medido de la causa

Del log de `WelcomeChooserUITests`:

```
t = 5.39s  Waiting 60.0s for "welcome_hero_cta" Button to exist
t = 6.51s  Tap "welcome_hero_cta" Button
t = 6.97s  Waiting 10.0s for "welcome_chooser_restore" Button to exist   ← se agota
```

O sea: **el Hero sale y se tapea; el chooser de nivel 1 no llega nunca.** Los identifiers no son el
problema — `WelcomeChooserView` los pone por interpolación
(`"welcome_chooser_\(branch.rawValue)"`, con `Branch` = `new` · `restore` · `invite`), así que un grep
del literal no los encuentra pero la app sí los emite. Las dos celdas de `SecondarySessionGateUITests`
mueren en el mismo sitio: su helper `walkToOrganizerGate` recorre Hero → `welcome_chooser_invite` →
`welcome_groups_create`.

⇒ lo que hay que mirar es **qué hace `WelcomeHeroView.handleEmpezar()` hoy bajo `-uitest`** y por qué no
acaba en `goTo(.chooser)`: el sospechoso natural es un encaminamiento nuevo del Hero (el faro, la sonda
de iCloud, el sub-chooser) que se lleva el tap antes de que el chooser se monte.

## Por qué `high`

- Son **siete** casos, y cubren el primer minuto de la app: elegir dónde viven tus datos, el
  encaminamiento del faro y las dos pantallas de la puerta de Grupos.
- La suite de UI **ya no corre en los PR**, solo en la nocturna, así que un rojo aquí no lo ve nadie
  hasta que alguien mira el run — y un rojo permanente se deja de mirar.
- Y cada rojo de estos **ciega una red viva**: las dos celdas de `SecondarySessionGateUITests` son
  exactamente las que el paso 5 del rediseño escribió para que la puerta del organizador no volviera a
  bloquear al dueño de los datos.

## Relación con lo que ya hay

`nocturna-del-9-sep-dejo-cuatro-xcuitest-en-rojo` es **otro** conjunto (`EdgeCasesUITests`,
`InboxConvertToGroupUITests`, `QuickActionsFavoritesUITests`, `TransactionsCrudUITests`) y otra causa
probable. Conviene atacarlos en la misma sesión: los dos tickets responden a la misma pregunta —«¿qué
más se rompió sin que la nocturna lo dijera?»— y el arreglo del canal de avisos ya está hecho.

## Cómo se sabe que está arreglado

Los siete en verde en un worktree limpio de `2.1`, y una línea en el ticket diciendo **cuál era la
causa**: si sale que era flaky de runner frío, a la Lista Negra con su fecha, que caduca.
