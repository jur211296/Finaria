---
name: la-asercion-que-no-puede-fallar
description: El control positivo por mutación valida el TEST, no cada ASERCIÓN — un caso con una aserción viva y tres vacuas sale rojo igual y parece verificado.
metadata:
  type: feedback
---

**Una aserción puede ser incapaz de ponerse roja, y el mutante no te lo dice.** El control positivo por
mutación demuestra que **el caso** caza el bug; no que cada `#expect` de dentro sirva para algo. Si una
sola aserción del caso es sensible al mutante, el caso entero sale rojo — y las demás pasan la
inspección de rebote.

**Why:** el 2026-09-08, en `chat-draft-drops-the-expense-sign`, escribí un tercer caso de test con
cuatro aserciones para vigilar que no se firmara **una sola** de las dos columnas de dinero. Corrí el
mutante, el caso salió rojo, lo di por bueno. Una lente adversarial midió después que:

- `#expect(tx.exchangeRate > 0)` **no podía fallar jamás**: producción persiste `exchangeRate:
  abs(effectiveRate)`, y ese `abs()` ya estaba antes de mi fix. Peor, su mensaje afirmaba que «si uno
  solo va firmado, sale negativa» — falso sobre este repo.
- `#expect(abs(tx.exchangeRate - 1.0) < 1e-6)` era ciega al mutante que decía vigilar: `abs(-1.0)` es
  `1.0`.
- Dos más eran copia literal de aserciones del fichero hermano, sobre el mismo escenario.

De cuatro, **una viva**. El caso salía rojo con el mutante por esa una, así que mi verificación parecía
completa. El caso entero se colapsó en el primero: menos aserciones, y una llamada menos a
`makeTestContext()`, que es recurso escaso.

**How to apply:**

- Antes de escribir un `#expect`, mira **cómo escribe producción esa columna**. Si la envuelve en
  `abs()`, la satura o le pone un default, tu aserción sobre su signo, su rango o su presencia puede
  ser tautológica. `git show HEAD:<fichero>` responde en un comando si esa defensa ya estaba.
- La prueba real de una aserción es: **¿qué mutación concreta la pone roja a ELLA?** Si no sabes
  nombrarla, sobra. Y si dos aserciones caen con la misma mutación, una sobra.
- Cuando un caso tenga varias aserciones y quieras saber si todas trabajan, el mutante tiene que ser
  **el de esa aserción**, no el del bug del ticket. Aquí eso era «firmar solo el monto nativo», que es
  distinto de «no firmar nada» — y era justo el que ninguna de las tres cazaba.
- Sospecha de la aserción que copiaste de otro fichero: si el escenario es el mismo, la cobertura ya
  existe allí y aquí solo añade ruido.

Relacionado: [[mi-docblock-tambien-es-una-premisa]] — el mensaje de un `#expect` es un docblock más, y
el mío afirmaba algo falso sobre producción. Y [[mutante-compilado-zanja-hipotesis]], que sigue siendo
la herramienta buena: lo que esta memoria acota es **qué** demuestra exactamente.
