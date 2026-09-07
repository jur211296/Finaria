---
name: review-adversarial-caza-lo-mio
description: La review adversarial no es para auditar código ajeno: en el ticket del invitado (2026-09-05) cazó cuatro defectos que introducía MI cambio, incluido el propio defecto del ticket colado por la puerta de atrás. Cómo montarla para que sirva.
metadata:
  type: feedback
---

**La review adversarial se corre sobre lo que acabo de escribir yo, y esperando que encuentre algo.** No
es un trámite de calidad sobre código heredado.

**Why:** en `groups-invite-skips-unirme-sheet-if-onboarded` (2026-09-05) tenía el fix implementado, 127
tests verdes y la mutación hecha. Dos lentes independientes encontraron **cuatro defectos que introducía
ese mismo cambio**, y el peor era el defecto del propio ticket colado por la puerta de atrás: confirmar
UNA invitación sellaba TODAS las demás, porque el CTA llamaba a `reconcile` sin decir de qué grupo
hablaba. Mi test de esa propiedad estaba **verde** — probaba el store llamando a la función a mano, no el
camino real. Además refutaron una afirmación que yo había escrito en tres sitios como si la hubiera
medido, y que era falsa.

**Y el 2026-09-07, en `groups-budget`, cuatro lentes encontraron ~20 y una evitó romper OTRA pantalla.**
El editor del tope tenía un botón condicional dentro del `actions` de un `.alert` — el patrón que
`swiftui-ds.md` tiene medido como «no rompe la alerta: rompe la app», con la víctima en un área que
ningún cruce de `codeGlobs` habría señalado. Dos más que ninguna suite podía ver: un tope de 15 dígitos
se perdía **en silencio** (el codec del wire lanza a partir de 1e14, quien traga el throw no crea la fila
de outbox y su log vive bajo `#if DEBUG`), y añadir una columna al manifest de Grupos ponía en
divergencia falsa al parque entero. ⇒ **con cuatro lentes, dos convergieron en el hallazgo más grave y
ninguna de las otras dos lo vio**: el reparto por especialidad no es redundancia, es cobertura.

**2026-09-07, `fx-pnl-education-card`: tres lentes, diez defectos, todos míos — y dos cambiaban el
SIGNO del número.** No la magnitud: el signo. La tarjeta anunciaba ganancia a quien había perdido,
por dos vías independientes (un gasto arrastrando el coste de entrada, y un traspaso entre cuentas
propias contando como compra). El cálculo se reescribió entero a media sesión.

**Y aquí las lentes CONVERGIERON en vez de contradecirse, que es la señal contraria a
[[lentes-adversariales-se-contradicen]] y hay que saber leerla:** dos lentes distintas, con encargos
distintos (una de corrección aritmética, otra de coherencia entre superficies), llegaron al MISMO
defecto de fondo por caminos distintos y con escenarios numéricos distintos. Cuando eso pasa, no es
redundancia ni casualidad: es que el defecto está en el **diseño**, no en una línea. Un hallazgo que
sólo ve una lente puede ser su especialidad; uno que ven dos por rutas distintas es estructural, y
la respuesta correcta suele ser rediseñar, no parchear.


**El patrón que más se repite en lo que cazan, y ya van tres sesiones: mi TEST del borde elige el
fixture que no puede fallar.** Aquí `gastarJustoElTopeNoEsPasarse` usaba UN gasto de 1000 — el único
caso donde el `>` de `Double` y el `>=` decimal coinciden trivialmente. Con tres importes que suman
1.000,00 exactos, la coma flotante da 1000.0000000000001 y la tarjeta decía «te pasaste por 0,00» en
rojo; el 16,5 % de los repartos caen ahí. Es la familia de `.claude/rules/testing.md` L72, cometida por
mí, en un test escrito para proteger justo eso. ⇒ **al escribir el test de un borde numérico, construye
el caso con VARIOS sumandos**, no con el número redondo que hace verdad la aserción por accidente.

**How to apply:**

- **Las dos lentes coincidieron, sin verse, en los dos hallazgos gordos.** Esa coincidencia es la señal
  de que un hallazgo es real; lo que solo dice una lente merece que yo lo mida antes de creerlo. Y de
  hecho **medí la refutación yo mismo antes de corregir** — la lente también puede equivocarse.
- **Dales una lente distinta a cada una, no «revisa esto».** Lo que funcionó: una sobre la máquina de
  estados (¿bucles?, ¿caminos donde no aparece?, ¿qué pasa si mata la app aquí?) y otra sobre regresiones
  y daño colateral en preferencias (¿qué escribe?, ¿a qué dominio?, ¿viaja cross-device?).
- **Pídeles que refuten su propio hallazgo antes de reportarlo, y que digan si sobrevivió.** Las dos
  descartaron cosas por su cuenta y marcaron una con «confianza media», que resultó ser real y estrecha.
- **Y el corolario que más duele:** un test verde escrito por mí sobre una propiedad que yo mismo definí
  puede estar montando el estado a mano y saltarse justo al caller que lo rompe. Cuando el test llama
  directamente a la función que quiero proteger, **no está probando el camino**.

Relacionado: [[mutante-compilado-zanja-hipotesis]] (la mutación prueba que el test vale; la review prueba
que el test mira donde hay que mirar — no se sustituyen) · [[mis-mediciones-fallan-por-el-filtro]].

**Refuerzo medido el 2026-09-06** (`groups-leave-rpc-error-10`, tres lentes: SwiftData/concurrencia,
producto/UX, y la mía de patrón). Cazó **seis** defectos míos, y dos hacían el fix **peor que el bug**:
(1) el reconciliador de ownership se convertía en una cárcel — tras el primer rechazo, el guard local
cortaba todo intento futuro antes de la red y ningún pull reabre `isOwner`; (2) un `save()` fallido
dejaba el flag vivo EN MEMORIA, con la UI ya ofreciendo una acción irreversible sobre un dato que no
estaba en disco. Los otros cuatro: copy circular que mandaba a la pantalla en la que ya estabas, un
comentario que prometía una reanudación que no ocurre, un docblock cierto para la función y falso como
efecto, y un doc-comment que mi propia inserción se había comido.

Dos cosas que aprendí del formato: **la lente refuta además de acusar** —me confirmó que NO debía usar
`saveUnderOutboxAuthor` (habría marcado con autor de eco ediciones ajenas pendientes, que el drain
descarta) y que el `incrementDataVersion` no ciclaba—, y eso vale tanto como los hallazgos. Y **una
lente de PRODUCTO encuentra lo que las técnicas no ven**: el callejón del dueño con deuda ajena y el
copy que apuntaba a una pantalla inalcanzable no los vio ninguna lente de código.


**Tercer refuerzo, 2026-09-07** (`welcome-privacy-branch-has-no-secondary-door`, tres lentes: flujo del
Welcome, el seed y los datos del alta, aislamiento de sesión). Y trajo una variante nueva que conviene
tener presente: **el defecto que más importaba NO estaba en mi diff**.

Una lente siguió el camino del usuario un tap más allá de mi pantalla nueva y encontró que
`clearResidualPreferencesForFreshStart` —que corre justo detrás del CTA— borraba el nombre y la divisa
del **dueño del teléfono**, y que la visita entra siempre por esa rama. Deuda previa, no la introduje
yo. Pero mi pantalla dice *«lo tuyo no se mezcla con lo suyo»*, así que **mi copy era falso una pantalla
después**: si no lo arreglaba, mi fix heredaba la forma del bug que venía a arreglar.

- **Al pedir la lente, di el camino, no solo el diff.** Lo que la encontró fue el encargo explícito de
  «recorre qué escribe cada salto y en qué dominio», no «revisa estos ficheros».
- **Un hallazgo fuera del diff puede ser tuyo igualmente**, si tu cambio lo pone en el camino o hace
  una promesa que él incumple. Ése se arregla; los demás van a ticket.
- **Y la lente también refutó bien**: descartó cuatro candidatos con la medición que los mataba —el
  portal que no puede desviar en secundaria, el `initialStep` que nadie escribe, el presupuesto cuya
  rama está muerta— y corrigió DOS frases mías que eran imprecisas, incluida una de un ticket que
  acababa de escribir. Pedir la refutación por escrito es lo que hace eso posible.

---

## Segunda vez, y el defecto grave venía envuelto en un razonamiento MÍO (2026-09-07)

`reentry-killswitch-closes-both-doors`. Tres lentes (sync/carrera, producto, regresión), **cuatro
defectos, los cuatro introducidos por mí**, con 6291 tests en verde y el mutante ya verificado.

El grave: reusé una fase de pantalla existente (`.bornCloudReady`) para la re-entrada, y **escribí en
el docblock la justificación** — «no son dos hechos distintos sino el mismo por dos caminos, con el
mismo copy, el mismo `canGoBack` y la misma salida». Sonaba a análisis. Era falso: lo que las separa
no es el camino sino la **precondición**. La re-entrada llega con `hasCompletedOnboarding` ya marcado
por `onAdoptStarted` —que existe *literalmente* para que «el seed del onboarding jamás corra sobre una
cuenta existente»— así que mi CTA mandaba al onboarding de 8 pasos a alguien con datos: cuenta
duplicada, categorías sembradas, y **subiendo al backend** porque el mismo chip acababa de arrancar el
motor en sesión. Estaba deshaciendo una defensa explícita del código mientras explicaba por qué era
seguro.

**Why (lo que esto añade a la ficha):** un razonamiento escrito con seguridad es la forma en que mis
defectos pasan desapercibidos, incluida a mí mismo al releer. La lente de regresión no discutió mi
argumento: fue a mirar **quién más escribe ese flag** y encontró la línea que lo invalidaba.

**How to apply:**
- **Reusar un caso/fase/estado existente porque «es el mismo hecho» es una hipótesis, no un diseño.**
  La prueba no es que compartan copy o pantalla: es que compartan **precondiciones y salida**. Si el
  callback único tuviera que adivinar cuál de dos estados tiene delante, son dos casos.
- **Cuando justifiques un reuso, busca quién más escribe el estado del que depende** (`grep` del
  setter, no del lector — es el caso 17 de [[mis-mediciones-fallan-por-el-filtro]]). En este chip la
  respuesta estaba a cuatro líneas del call-site, en un comentario que decía para qué existía.
- **Las tres lentes encontraron cosas distintas y ninguna sobró**: producto cazó el botón que no podía
  cambiar su desenlace, sync el guard que tiraba la mitad de su dato, regresión la salida al
  onboarding y el poll que no paraba. Con dos lentes me habría faltado una.
- Y una que ya sabía y volvió a cumplirse: **dos de los cuatro los había cazado yo antes** (el
  `force: true` lo encontré leyendo el patrón del repo). La review no sustituye la auto-revisión;
  encuentra la clase de cosa que la auto-revisión no ve porque es donde yo *creo* que ya pensé.

## 2026-09-07 — ocho defectos, y el peor era una decisión que yo había razonado al revés

Recordatorio de liquidación (PR #89). Tres lentes: cálculo, ciclo de vida, producto. **Los ocho eran
míos**, con el build en verde y 6316 tests pasando.

**El grave repite la forma del 2026-09-06: no era un descuido, era un razonamiento explícito y
equivocado, escrito con confianza en un comentario.** Decidí respetar `simplifyDebts` «para que el
aviso diga lo mismo que la pantalla», y suena bien. La lente no discutió el principio: **montó el
caso numérico**. Con simplificación, la arista «yo → X» no la produjo ningún gasto entre X y yo —
es un enrutado de mínimo flujo de caja sobre saldos de **terceros** — así que el aviso podía decir
«lleva semanas quieta» sobre dinero de anoche, con un importe **7,6× el real**; y de paso rompía el
rate-limit, porque su clave (`Debt.id`) cambiaba cuando dos personas **que no soy yo** se pagaban
algo. Coherencia con la pantalla era el criterio correcto para un *saldo* y el equivocado para una
*afirmación temporal*, que es lo que este feature añade.

**Y el que peor se habría escondido:** mi espera de frescura salía en el primer poll porque un solo
grupo legacy en el store cuenta como `.fresh` incondicional. El feature habría quedado **mudo en el
arranque, en verde y sin un solo síntoma** — exactamente el modo de fallo del que el docblock del
repo avisa, reintroducido por mí **en el mismo commit en que copié ese docblock para citarlo**.

**Lo que me llevo, y es nuevo:** cuando reuso una primitiva ajena, la pregunta no es «¿la estoy
llamando bien?» sino **«¿mi pregunta es la misma que la suya?»**. `GroupChannelFreshness` contesta
«¿puedo afirmar que esto NO EXISTE?»; yo preguntaba «¿está completa mi foto de deudas?». Mismo
`isFresh`, significados opuestos para una zona sin canal. El conteo de call-sites que debía cazar el
cuarto consumidor **no se puso rojo**: su lista de ficheros es explícita y un fichero nuevo le es
invisible. ⇒ **un escáner de cableado prueba que el cambio se aplicó, nunca que sea correcto**, y
ese punto ciego concreto —lista explícita de ficheros— hay que mirarlo antes de confiar en él.
