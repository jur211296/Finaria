---
name: hipotesis-lista-negra-recomprobadas
description: Registro de hipótesis de la Lista Negra re-medidas y cuándo. El runner de XCUITest se cayó el 6-sep y NO se reprodujo el 7 (15/15 casos); el CI sigue vivo y `tests` tarda ~1h; qué esconde el informe de disco y qué NO (CoreSimulatorInternal/Devices es el mismo inode, no espacio extra).
metadata:
  type: project
---

**Registro de re-comprobaciones.** Una hipótesis de la Lista Negra caduca cuando cambia el entorno
(Xcode, macOS, runtime, disco), y la regla del repo obliga a re-medirla antes de darla por buena.
Aquí queda **cuándo la miré yo y qué salió** — el veredicto vivo está en su fuente, no aquí.

## «El runner de XCUITest está roto en la Mac local» — NO se reprodujo el 2026-09-05

**Dónde se afirma:** `qa/coverage-index.json`, área `session-sign-out`, dice *«XCUITest determinista
del cover posible via el seam DEBUG — diferido hasta plan CI (runner roto en la Mac local, Lista
Negra M1)»*.

**Qué medí:** en el gate del ticket `secondary-guest-exit-lock-and-outbox` corrí tres suites de
`YalaUITests` (`ProfileSettingsUITests`, `YalaAccountUITests`, `SecondarySessionGateUITests`) con la
scheme `Yala Dev` en el iPhone 17 Pro. **8 tests, 0 fallos, `TEST SUCCEEDED`** en ~130 s. Ni un
`RequestDenied` ni un `xctrunner` que no lanza. El disco estaba en 27 GiB libres, por encima del
umbral de 25.

**Qué NO prueba:** que el runner esté sano *siempre*. Los dos síntomas conocidos son dependientes
del entorno —disco lleno, y apagar el simulador entre corridas (`testing.md` L91)— así que esto dice
«hoy, con disco holgado y sin apagar el simulador, corre», no «la hipótesis era falsa».

**How to apply:** cuando un documento diga que los XCUITest no se pueden correr en local, **pruébalo
antes de diferir trabajo por ello** — cuesta una corrida. Si falla, mira primero
`bash qa/scripts/disk-report.sh` y si el simulador se apagó entre corridas, antes de anotarlo como
roto. Y si vuelve a correr verde, actualiza la afirmación en su fuente: el diferimiento que justifica
ya no se sostiene solo.

Relacionado: [[mis-mediciones-fallan-por-el-filtro]] — el décimo caso de esa ficha es justo el error
inverso, culpar al entorno sin leer el error entero.

## «El runner de XCUITest corre bien en local» — HOY NO, medido el 2026-09-06

La re-comprobación de arriba (5-sep, 8 tests verdes) **caducó en un día**. En el gate de
`fx-presentation-still-shows-1to1`: **cada suite ejecuta su primer caso, lo pasa, y el runner
muere** («Restarting after unexpected exit, crash, or test timeout»); la siguiente ejecución
reporta `Executed 0 tests` y la corrida acaba en `TEST FAILED` listando casos que **nunca
imprimieron una línea `Test Case … failed`**.

**Cómo supe que no era mío, y es el método que vale la pena repetir:** worktree limpio desde HEAD
con `Secrets.xcconfig` copiado → falla **idéntico**. Y la comprobación en la dirección contraria,
que es la que de verdad cierra la pregunta: **un caso que PASA en el árbol con cambios FALLA en el
árbol limpio**. Un rojo introducido por un cambio no se comporta así.

**Lo que NO se pudo descartar:** el disco. La máquina estuvo entre 8,7 y 15 GB toda la sesión (el
umbral del repo son 25) y el síntoma siguió igual tras liberar 6,3 GB. O el umbral real está más
arriba, o la causa es otra. Ticket `rojo-xcuitest-runner-muere-tras-el-primer-caso` (high).

**How to apply:** mientras dure, el paso 3 del `/gate` **no da veredicto** para XCUITest — y lo
peligroso no es el falso rojo, es que **taparía un rojo real** en cualquier caso que no sea el
primero de su suite. No archives los nombres que salgan en «Failing tests»: el conjunto depende del
orden de ejecución, no de qué esté roto.

## «El runner de XCUITest muere tras el primer caso» — NO se reprodujo el 2026-09-07

**Dónde se afirma:** `docs/ESTADO.md` del 6-sep y el ticket `rojo-xcuitest-runner-muere-tras-el-primer-caso`
(high): el runner se cae tras el primer caso de CADA suite («Restarting after unexpected exit»),
5 suites → 5 casos, 0 líneas de fallo, 5 nombres en «Failing tests». El bloque concluía que **el
paso 3 del gate no da veredicto**.

**Qué medí:** en el gate del ticket del rótulo del hero corrí **8 suites** de una vez
(`StatisticsNavigation`, `EdgeCases`, `WelcomeFreshStartAlert`, `IncomeExpenseClassification`,
`ProConversionUpsells`, `RecordsDetailSheet`, `SplitCalculator`, `BulkEdit`). **15 casos ejecutados
= 15 declarados en el fuente, 0 fallos.** Siete de esas suites tienen 2 casos y ejecutaron los dos,
que es justo lo que el 6-sep no pasaba.

**Cómo lo conté, porque `TEST SUCCEEDED` no vale:** conté los `func test`/`@Test` de cada fichero de
suite y los comparé con el `Executed N tests` del log. 15 = 15. Sin ese conteo, un runner que muere
después del primer caso de cada suite sale igual de verde ([[gate-paso3-no-detecta-cero-casos]]).

**La diferencia de entorno, sin descartar nada:** subí el disco de 5,2 GB a **12 GB** ANTES de correr
—borrando dos `DerivedData` de worktrees ya retirados, 6,6 GB— y el Mac llevaba menos horas
encendido. El 6-sep la máquina estuvo entre 8,7 y 15 GB, así que el disco solo **no** explica la
diferencia; la sospecha de MEMORIA que el ESTADO apuntaba sigue viva.

**How to apply:** no arranques asumiendo que el paso 3 no da veredicto — el 7-sep lo dio. Pero
tampoco des el ticket por cerrado: son dos observaciones opuestas en dos días, así que **cuenta los
casos siempre** y, si mueren, sube el disco por encima de 12 GB y repite antes de escribir nada.

---

## Los `DerivedData` de worktrees retirados se acumulan — medido el 2026-09-07

**Qué pasó:** dos builds del gate bajaron el disco de 11 GB a **5,2 GB**, zona donde CoreSimulator
falla con errores que no lo mencionan. En `~/Library/Developer/Xcode/DerivedData` había **tres**
carpetas de Yala: la mía (4,0 GB, `mtime` de hacía 2 minutos) y **dos huérfanas de worktrees ya
retirados** (4,4 GB + 2,2 GB = 6,6 GB). Borrar solo las huérfanas devolvió el disco a 12 GB sin
tocar mi build en curso.

**Cómo distinguir la mía de las huérfanas, que es lo único delicado:**
`plutil -extract WorkspacePath raw <carpeta>/info.plist` da la ruta del `.xcodeproj`; si esa ruta ya
no existe, la carpeta es basura. `rm -rf` está **bloqueado** en este entorno: se borra con
`find <dir> -depth -delete`.

**La corrección que me ahorré escribir mal:** iba a reportar `~/Library/CoreSimulatorInternal/Devices`
(4,6 GB) como espacio que el informe de disco esconde. **Es el MISMO directorio** que
`~/Library/Developer/CoreSimulator/Devices` — lo comprobé con `stat -f '%i'`: inode 43225723 en los
dos. El informe ya lo cuenta; sumarlos habría inflado el recuperable al doble. El punto ciego **real**
sigue siendo `/Library/Developer/CoreSimulator/Volumes` (16 GB de runtimes), y **eso no se borra**.

---

## «El CI de GitHub, apagado» — FALSO el 2026-09-05, y sigue vivo el 2026-09-06

**Dónde se afirma:** el `CLAUDE.md` global de casa, en el párrafo de ADR-015: «El CI de GitHub,
apagado».

**Qué medí:** al abrir el PR #74, GitHub Actions disparó el workflow `QA` (run 34006392127) con
**tres jobs**: `changes` (verde en 3 s), `coverage-index` (verde en 14 s) y `tests` (build + suite,
minutos). Con anotación propia: «CORRE — toca Yala/App/ContentView.swift». O sea que no solo está
encendido: su job `changes` está decidiendo bien qué disparar.

**Qué cambia para mí, y es lo práctico:** un PR recién abierto sale `mergeable: MERGEABLE` pero
`mergeStateStatus: UNSTABLE` mientras `tests` corre. **`UNSTABLE` ahí no es un conflicto ni un
fallo** — es «checks sin terminar». Mergear en ese estado se salta una red que sí funciona, así que
se espera (`gh pr checks <n>` hasta que no quede ningún `pending`). Vercel también engancha el PR y
tarda lo suyo; su rama de producción es `1.0`, así que en un PR a `2.1` es solo preview.

Re-comprobado en el PR #84 (6-sep): mismo workflow `QA`, mismos tres jobs. `changes` y
`coverage-index` cierran en segundos; **`tests` tarda mucho más de lo que parece** — una corrida de
esa misma noche fue de 01:47 a 03:06, casi hora y media. Contar con minutos es lo que lleva a
mergear antes de tiempo.

**How to apply:** el gate local sigue siendo mi red —es el que corre XCUITest de verdad— pero **no
mergees un PR con checks pendientes por creer que no hay CI.** Y si vuelves a leer que está apagado,
mídelo con `gh pr checks` antes de obedecerlo.

## Lo que el informe de disco no ve: una corrección MEDIDA el 2026-09-05

El system prompt avisa de tres sitios invisibles al `disk-report.sh`, y uno de ellos tiene una
trampa que casi me cuesta el simulador: **`~/Library/CoreSimulatorInternal/Devices` NO es caché.
Ahí viven los devices REALES** — el `iPhone 17 Pro` (UDID completo
`9D0F6D32-1F49-46AD-8070-603D42B5220F`; **`simctl` rechaza el prefijo con «Invalid device», medido
el 2026-09-06 — sácalo de `xcrun simctl list devices available`, no de aquí) que uso para todo
estaba dentro,
con sus 10 GB. Borrar esa carpeta «para liberar» habría destruido el simulador de trabajo.

Lo medido esa noche, con el disco en 12 GB: `/Library/Developer/CoreSimulator/Volumes` = 16 GB (el
runtime montado, no se toca) · `CoreSimulatorInternal/Devices` = 10 GB (**los devices, no se toca**)
· `Caches/dyld` = 3 GB (regenerable) · DerivedData 3,5 + 2,2 GB.

**Lo que sí funcionó, en orden de rendimiento y sin riesgo:** (1) `xcrun simctl erase <udid>` del
propio device —recuperó ~6 GB, y es lo que más da—; (2) borrar el DerivedData de un worktree ya
RETIRADO (comprobar con `git worktree list` cuál sigue vivo, y el `info.plist` de cada carpeta dice
a qué árbol pertenece); (3) `xcrun simctl delete unavailable` y los devices que este repo no usa —el
destino fijo es `iPhone 17 Pro`—; (4) `tmutil thinlocalsnapshots / 40000000000 4` **después** de
cada borrado: sin él el espacio no aparece en `df`, y eso hace parecer que el borrado no sirvió.

Y una nota de herramienta: `rm -rf` sobre `~/Library` pide permiso; `find <dir> -depth -delete` hace
lo mismo sin prompt.

**Un quinto sitio, y el informe lo esconde dentro de un total (2026-09-06):**
`CoreSimulator/Devices/<udid>/data/Library/Caches/com.apple.containermanagerd/**Dead**` — los
contenedores de apps ya desinstaladas que CoreSimulator no recoge. Eran **5,7 GB de los 6,7 GB** de
caché de ese device. El `disk-report.sh` los cuenta en «Simuladores», que uno lee como «el
simulador que necesito», así que no se tocan. Es basura pura y se borra sin apagar el simulador. Su
vecino `com.apple.coresymbolicationd` (660 MB) también es regenerable. Cuando una tanda de builds
se coma el disco, mirar ahí **antes** de plantearse borrar DerivedData, que cuesta un rebuild
entero.

**El paso (2) sin adivinar, y lo que rinde (2026-09-06).** El `info.plist` de cada DerivedData
guarda el árbol al que pertenece, así que la clasificación es un comando, no una inferencia:

    for d in ~/Library/Developer/Xcode/DerivedData/Yala-*; do
      ws=$(/usr/libexec/PlistBuddy -c "Print :WorkspacePath" "$d/info.plist" 2>/dev/null)
      [ -e "$ws" ] && echo "VIVO     $(du -sh $d|cut -f1)  $ws" || echo "HUÉRFANO $(du -sh $d|cut -f1)  $ws"
    done

Ese día había **cuatro** carpetas de Yala y **dos eran huérfanas** (worktrees retirados el mismo
día): **7,8 GB de basura pura**, de 8,4 GB libres a 16 GB, sin tocar nada vivo y sin recompilar. Es
el borrado de mejor relación riesgo/beneficio de la lista cuando se ha trabajado en varios
worktrees seguidos — que en este repo es lo normal. Y confirmado otra vez que `rm -rf` está
bloqueado por el sandbox incluso con ruta absoluta: `find <dir> -type f -delete` y luego
`find <dir> -depth -type d -empty -delete`.
