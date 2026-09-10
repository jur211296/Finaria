---
name: la-premisa-del-encargo-tambien-se-mide
description: El encargo hereda las premisas falsas del ticket y medirlas cambia el trabajo; y la cara B — a veces la premisa es buena y el que la leyó mal fui yo, así que la CORRECCIÓN también se mide antes de publicarla
metadata:
  type: feedback
---

La regla «mide antes de obedecer a un documento» **incluye el propio encargo**, no solo el ticket y
las docs del repo. El encargo lo redacta Jürgen leyendo el ticket, así que hereda sus errores y
llega con el tono de un hecho establecido.

**Why:** el 2026-09-06, el encargo de `groups-leave-rpc-error-10` afirmaba en su sección «Contexto»
que el caso #10 era `channelDisabled` (kill-switch) y avisaba «no confundir con `ownerCannotLeave`
(eso sería otra frase)». Era exactamente al revés, y el propio ticket marcaba esa lectura como
*inferencia sin comprobar*. Medirlo costó un script de Swift de 40 líneas: el tag que Foundation
imprime **no sigue el orden de declaración** (los casos con payload van primero). Con la premisa
buena, las dos «caras» que el ticket separaba resultaron ser el mismo defecto, y el punto 4 del
encargo («si el 10 es canal apagado…») se quedó sin objeto.

**How to apply:** cuando el encargo afirme un hecho **verificable** —un número, una coordenada, qué
caso de un enum es cuál—, mídelo antes de construir encima, sobre todo si el ticket de origen lo
marcó como inferido. No bloquea: el trabajo suele seguir siendo el mismo (aquí, «dar copy honesto»),
pero cambia cuál es el caso protagonista y qué hay que arreglar de verdad. Y díselo — no como
corrección, sino como el dato que reordena el ticket. Ver [[review-adversarial-caza-lo-mio]] y
[[mis-mediciones-fallan-por-el-filtro]].

## Segundo caso, el mismo día, y más fuerte: el defecto YA estaba arreglado

El encargo de `groups-pending-member-can-open-group` (2026-09-06) pedía «cerrar la puerta en el
cliente: la tarjeta del grupo no abre el detalle mientras el miembro esté en `pendingApproval`».
Medido antes de escribir código: **la tarjeta ya no lo abría**. `GroupCardView.handleTap` tenía un
`case .pendingApproval` que no navegaba desde `#26`, y el doc del helper lo decía con todas las
letras.

Lo que fallaba en el reporte de campo (TestFlight build 12, 28-ago) era la **identidad** que
alimentaba ese gate: `currentMemberStatus` resolvía por el flag `isCurrentUser`, que
`GroupsSyncClient.applyMember` **nunca enciende**, así que a quien llegaba por el pull le devolvía
`nil`, el modo caía en `.active` y la tarjeta abría. Y eso lo arregló **otro ticket**, `5ca4dd47`
(4-sep), ya en `2.1`. Dos comandos lo zanjaron: `git log -L '/func currentMemberStatus/,+4:<f>'` y
`git branch -a --contains`.

**Why:** el encargo describía el síntoma de un build de hace nueve días como si fuera el estado de
hoy. En un repo donde entran varios PR al día, **un reporte de campo caduca**, y el trabajo que
describe puede haberlo hecho ya un vecino sin saberlo. Si hubiera «cerrado la puerta» sin medir,
habría escrito un gate encima de otro y declarado arreglado algo que ya lo estaba — sin tocar
ninguna de las tres cosas que sí seguían rotas.

**How to apply:**
- Cuando el encargo venga de un **reporte de device con fecha y build**, lo primero es preguntarse
  «¿sigue vivo en `2.1`?». `git log -L` sobre la función sospechosa y `git branch --contains` sobre
  el commit que salga cuestan un minuto y contestan.
- **Que la premisa sea falsa casi nunca cancela el trabajo**: aquí quedaban tres cosas reales (el
  tap era un muro mudo, había dos puertas más sin gate, y el copy prometía lo que la decisión
  eliminaba). Lo que cambia es **cuál es el trabajo**, no si lo hay.
- Y díselo a Jürgen en esos términos: «el bug que reportaste ya no se reproduce, lo cerró X; lo que
  encontré abierto es esto otro». Ver [[mis-mediciones-fallan-por-el-filtro]].

## 2026-09-07 — la variante silenciosa: la cifra no era falsa, era de la magnitud equivocada

En `el-job-de-tests-del-ci-no-tiene-timeout` el ticket traía una tabla de duraciones y una
conclusión: «~80 minutos de media», con la recomendación de «un `timeout-minutes` alrededor de 120».
Nada de eso era mentira. Pero:

- **la muestra eran 4 runs.** Con los 39 que había (todos los que dispararon el job en dos días), la
  mediana real es **89**, no 80, y el p95 sube a 99,5. Cuatro puntos no sostienen un percentil, y el
  ticket llamaba «percentil alto» a lo que era el máximo de cuatro.
- **y sobre todo, medía el objeto equivocado.** La decisión que el propio ticket recogía sacaba la
  UI del PR; en cuanto la sacas, el número que gobierna el tope del PR ya no es el del job entero
  sino el de **build + unit**, que nadie había medido: p95 **27,2**, máximo **29,9**. El «alrededor
  de 120» del ticket habría sido un tope cuatro veces mayor que el peor caso real — o sea, ninguno.

La única forma de ver esto fue medir **por paso**, no por job (`/actions/runs/<id>/jobs` trae cada
step con `started_at`/`completed_at`). Coste: un bucle de `gh api` y un script de 30 líneas.

⇒ a la lista de premisas verificables se añade una que no parece premisa: **una cifra correcta pero
agregada al nivel equivocado**. La pregunta no es «¿es cierto este número?» sino «¿mide el objeto
que mi decisión va a acotar?». Cuando la decisión cambia la forma del trabajo —aquí, partirlo en dos
corridas—, las mediciones del ticket describen un mundo que ya no existe, y sirven de línea base, no
de respuesta. Y desconfía de un percentil con menos de ~20 puntos: dilo como «máximo observado».

## 2026-09-08 — la premisa que dice DÓNDE NO MIRAR es la más cara de todas

`goldens-de-staging-solo-pasan-a-trozos` afirmaba, en negrita y como el hecho central del
diagnóstico: **«Los 10 fallos son timeouts. Cero aserciones fallidas — ni una en ninguna corrida.
Eso importa: no hay ningún fallo de lógica.»**

Había dos fallos de aserción, y **eran la respuesta entera**. El bump de canon a `c2` del 7-sep
había dejado dos `expect(...).toBe("c1")` sin actualizar. El ticket incluso los tuvo delante: su
corrida 3, con el manifest sincronizado, dio «14 · 11, ligeramente PEOR» — esos dos rojos nuevos
eran los asserts, y se leyeron como ruido que empeoraba la hipótesis en curso.

Y no era la única premisa falsa del mismo ticket: los conteos de grupos estaban **cruzados** entre
los dos usuarios y con otros números (decía A=677/B=511; medido, A=530/B=678), lo que importaba
porque la hipótesis apuntaba al usuario A y el test que más sufre pullea al B. El «factor 70x, ~69 s
por test» era el promedio de repartir el total entre 25 tests que van de 0,0 s a 130 s.

**Why:** una premisa que dice «no hay nada de esta clase» es una **poda del espacio de búsqueda**, y
por eso cuesta más que una cifra mal copiada: no te manda a un sitio equivocado, te prohíbe uno
correcto. Aquí bastó correr la suite una vez mirando el tipo de cada fallo — 5 minutos — para
tumbarla.

**How to apply:** cuando un ticket clasifique los fallos («todos son timeouts», «todos de la misma
familia», «ninguno es de lógica»), esa clasificación es una **afirmación verificable y barata**, no
un contexto. Re-córrelo y clasifica tú. Es la versión de «cuando un documento te diga no mires aquí,
mira» aplicada a la taxonomía del propio fallo. Ver [[rojo-conocido-no-exime-de-bisecar]].

---

## La premisa «esto no se puede probar en simulador» es la más cara de todas (2026-09-08)

En el barrido de `tickets/qa/` **tres** tickets declaraban en su propio cuerpo que su verificación
era imposible en simulador. Las tres eran falsas, y las tres llevaban meses **inflando la cola de
device-QA de Jürgen**:

| Lo que decía el ticket | Lo que medí |
|---|---|
| «Ningún seed es multi-divisa (son PEN)» | `DevSeedAccounts.swift:22-36` crea cuenta **PEN** y cuenta **USD** |
| «No hay histórico real de tasas con una fila incompleta» | Las filas sembradas traen **solo PEN/EUR/USD** de 48 divisas: parciales **por construcción** |
| «La card de P&L no aparece en XCUITest; su cobertura es cero por construcción» | Aparece con el seed `minimal`, sin tocar nada |

Y el `docs/ESTADO.md` que yo mismo escribí repetía la primera.

**Why:** esta familia es peor que una coordenada envejecida por dos motivos. Uno, **se
autoconfirma**: nadie intenta lo que el documento declara imposible, así que la premisa nunca se
contrasta y se copia de ticket en ticket (aquí saltó de un ticket de FX a otros dos y al ESTADO).
Dos, **su coste no es tiempo perdido sino trabajo desviado a la persona equivocada**: cada una de
esas tres frases mandaba a Jürgen a coger el teléfono para algo que se veía en 5 minutos aquí.

**How to apply:** cuando un ticket diga «necesita device», «no es simulable» o «cobertura cero por
construcción», trátalo como **la afirmación más sospechosa del fichero**, no como el contexto.
Comprobarlo cuesta un `grep` al seed: `DevSeedAccounts`, `DevSeedExchangeRates`, `DevSeedGroups`
dicen exactamente qué corpus existe. Y la pregunta que separa de verdad las dos colas no es «¿el
camino real pasa por la red?» sino **«¿se puede sembrar el ESTADO FINAL que hay que mirar?»** — casi
siempre sí. Lo que de verdad no se simula es corto y reconocible: push APNs de verdad, sign-in real,
un RPC que devuelve un código que solo emite el servidor, Apple Pay, y dos teléfonos a la vez.

Corolario que salió el mismo día: **a veces el bloqueo es real pero la causa está mal atribuida.**
`groups-owner-transfer-and-leave` figura como device-QA, y lo que impide verlo es que **ningún
perfil de seed escribe `userID`**, así que `eligibleHeirCount` es siempre 0 y el botón no se pinta.
Eso no lo arregla un teléfono: lo arregla el seed. Distinguir «no se puede aquí» de «no se puede
**todavía** aquí» es lo que convierte una cola física en un ticket de backlog.

## Y la premisa heredada no siempre es del encargo: el 2026-09-09 vino del `docs/ESTADO.md`

El NOW decía «**cinco** tickets de FX bloqueados por `qa-no-puede-crear-cuenta-en-otra-divisa`», y
escribí «éste es el **sexto**» en el ticket, en el PR y a punto de mandarlo. Al contar: **tres** se
declaran *no* simulables por esa causa y **dos** más piden el mismo montaje declarándose *sí*
simulables. Ni cinco ni seis, y la diferencia importa porque esa cifra es la que justifica priorizar
la palanca.

**Why:** una cifra de un documento se copia sin fricción — no parece una afirmación, parece un dato.
Y en este repo la documentación envejece más rápido que el código.

**How to apply:** **toda cifra que vayas a REUSAR se re-mide**, venga del encargo, del ticket o del
estado. Cuesta un `grep -rl`. Y si al medirla sale otra, dilo en el sitio donde la reusaste **y
corrige el documento de origen**: dejarlo pasar es lo que hace que la próxima sesión herede el mismo
número.

## La cara B, y da más vergüenza: la premisa era buena y el que leía mal era yo (2026-09-10)

En el paso 0 del rediseño (`retire-guest-vocabulary-for-session-terms`) el ticket decía: «los dos
strings ES **y sus 15 hermanos** se retiran cuando `WelcomeGroupsGateView` pierda la rama
secundaria». Medí `welcome.groups.secondary*` en el catálogo ES, salieron **dos** keys, y escribí en
el ticket y en el PR una fila que decía «**Falso: son 2**».

Estuvo a punto de quedarse escrito. Los «15 hermanos» **son los otros 15 locales**: la app tiene 16
y las dos keys viven en los 16, así que el paso 12 retira **32 strings**, no 2. El ticket tenía
razón, y mi «corrección» habría metido en el repo un error donde no lo había — con el agravante de
que iba en la tabla de «lo medido», que es la que la próxima sesión creerá sin comprobar.

**Why:** todo lo de arriba entrena a buscar dónde miente el documento, y eso crea el sesgo
contrario: cuando un número no casa con mi medición, la explicación cómoda es que el documento se
equivocó. Casi siempre hay una tercera lectura —una palabra que significa otra cosa en ese
dominio— y no cuesta nada descartarla. Aquí bastó `ls Yala/Resources/*.lproj | wc -l`.

**How to apply:**
- **Una corrección es una afirmación, y se mide igual que la premisa que corrige.** Antes de
  escribir «el ticket dice X y es falso», pregúntate qué tendría que ser cierto para que X lo fuera.
  Si esa lectura existe y no la has descartado, no publiques la corrección.
- Sospecha de las palabras vagas de un ticket —«hermanos», «variantes», «los demás»— **en el dominio
  del ticket**: en l10n «hermano» es un locale, no una key.
- Y el corolario del mismo día: **el checklist de un ticket puede llegar hecho a medias.** Cuatro de
  las cinco entradas de glosario que este pedía **ya existían**, escritas por el commit del propio
  ADR. Comprobar el estado real antes de escribir cuesta un `grep` y evita re-escribir encima. Es la
  misma familia que «el defecto YA estaba arreglado», pero por dentro del alcance en vez de fuera.
