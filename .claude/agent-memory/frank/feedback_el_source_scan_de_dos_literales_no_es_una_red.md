---
name: el-source-scan-de-dos-literales-no-es-una-red
description: Cuando un test de fuente es la ÚNICA red posible (código en un target inalcanzable), grepear dos literales no basta: hay que fijar el cuerpo entero normalizado, paso a paso y con el orden.
metadata:
  type: feedback
---

Si un source-scan sustituye a un test de comportamiento **porque el código está en un target que la
suite no compila**, el scan tiene que fijar el **algoritmo entero**, no dos constantes.

**Why:** el 9-sep repliqué `ApproximateMarkThreshold` en el target del widget (no se puede importar:
solo tres ficheros de `Yala/` están en su membership exception) y escribí una «paridad» que grepeaba
`let fraction = 0.05` y comparaba el original contra **una tercera copia escrita en el propio test**.
La review adversarial lo tumbó: invertir los dos guards, cambiar `>=` por `>` o quitar la tolerancia
relativa dejaba las dos suites en verde. El docblock del test prometía «compara las dos
implementaciones» y no comparaba la del widget con nada. Verificado con el mutante: guards
invertidos → verde antes, rojo después de reescribirlo.

**How to apply:** normaliza el cuerpo (líneas trimmeadas, sin comentarios, unidas por espacio) y
afirma **cada paso literal en una lista**, más el ORDEN de lo que sea sensible al orden (`#require`
de los dos rangos y compara `lowerBound`). Y comprueba si la suite alcanza el target antes de
escribir «lo fija X»: `project.pbxproj` → `fileSystemSynchronizedGroups`. Es la familia de
[[mi-docblock-tambien-es-una-premisa]], aplicada a la cobertura entre targets.

**Tres hermanos del mismo día, y los tres pasaban en verde:**

- **La pasarela que nadie vigila.** Un componente intermedio (`WidgetKPI`, `PanelSmallBarRow`) que
  solo reenvía un parámetro: todos los tests miran los CALLSITES, aguas arriba, y borrar la línea de
  reenvío apaga la feature aguas abajo sin un rojo. Si un cambio pasa por un cuello de botella, ese
  fichero necesita su propia aserción.
- **El `contains` suelto no caza un SWAP.** Afirmar que el scope contiene `incomeAmountsAreApproximate`
  y `expenseAmountsAreApproximate` pasa con los dos casos del `switch` intercambiados. Fija el
  emparejamiento entero (`case .income: return summary.income…`), no la presencia.
- **El escenario que no recorre la rama que dice.** Mi caso del «régimen cerrado» tenía la
  transacción fuera del intervalo, así que salía por «sin datos» — otra rama que devuelve el mismo
  literal. Añade el control del escenario (`#expect(cerrado.hasDataInPeriod)`) o el test se sostiene
  por casualidad.

**Y un detalle que este repo ya había resuelto y yo no reusé:** los scans que CUENTAN ocurrencias
deben filtrar comentarios (`codeOnly`, en `WidgetSessionSealTests`). Sin él, documentar el invariante
que el test cuenta lo pone en rojo sin que producción cambie — la forma más tonta de que una red deje
de usarse.
