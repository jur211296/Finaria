---
name: el-reparador-tan-reejecutable-como-el-destructor
description: Si añades una reposición dentro de un hook kill-safe, tiene que poder re-ejecutarse tantas veces como el borrado que repara — consumir su fuente la destruye en la segunda pasada.
metadata:
  type: feedback
---

Cuando metas un paso que REPONE algo dentro de un hook que ya declara ser kill-safe, comprueba qué
pasa en la SEGUNDA pasada. Un hook idempotente se re-ejecuta entero tras un kill: si tu reposición
consume su fuente y el resto del hook vuelve a destruir lo repuesto, el destructor se re-ejecuta y
el reparador no.

**Why:** el 2026-09-11, en la puerta del invitado, puse `consume()` en la reposición del sobre
`{groupID, token}` que cruza el boot-wipe. Su `resetPrefs()` vacía `PendingJoinStore`; un kill entre
la reposición y el desarme (un tramo largo: notificaciones, colas del App Group, barrido de
sentinels — y corre PRE-MOUNT, bajo el watchdog de lanzamiento) dejaba el arm puesto, el arranque
siguiente re-ejecutaba el borrado entero y la reposición ya era un no-op. **La invitación moría por
la propia re-entrada que el orden kill-safe existe para tolerar.** Lo cazó una lente adversarial, no
un test.

**How to apply:** la lectura es `peek`, y la retirada de lo one-shot va PEGADA al desarme, con el
resto de lo one-shot del hook. La pregunta que lo destapa en diez segundos: «¿qué hace la segunda
pasada?». Y el test que lo fija ejecuta el par (vaciar + reponer) DOS veces y exige que la segunda
también reponga.

Dos primos que salieron del mismo sitio y valen igual:

- **Una superficie que existe para sobrevivir a un borrado es, por construcción, la única de su
  familia que no muere sola** ⇒ toda frontera que barra a sus hermanas tiene que nombrarla a mano
  (`SecondarySessionBoundaryPurge` barría las otras tres superficies de join y no la mía), y necesita
  **TTL propio**: sin él, un borrado que aborta la deja huérfana y el cierre de sesión de OTRA persona
  la revive meses después.
- **Lo que se escribe «cuando el trabajo queda armado» llega tarde si el armado desmonta la vista.**
  El sobre iba en el callback del arm, y en el camino del swap in-process la jerarquía —la pantalla
  incluida— se desmonta en la misma vuelta. Se escribe en el GESTO, que es inerte hasta que alguien
  lo consuma.

Ver [[review-adversarial-caza-lo-mio]] y [[un-gate-derivado-de-una-ausencia-falla-abierto]].
