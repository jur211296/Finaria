# Shot cards — `ia-gasto-pizza`

Los planos de la pieza piloto, decididos antes de tocar la composition. Es lo que aporta el
catálogo de planos (`video-shotcraft` / `ai-product-video`): **decidir cuántos planos hay y
qué hace cada uno**, no renderizar su template.

Cuatro planos, 17,2 s. El footage no se corta —es una toma continua de 16,18 s— así que los
«planos» aquí son **tramos de intención**, no cortes de montaje. Eso es deliberado: cortar
una demo de producto rompe la prueba de que la app hace eso de verdad, seguido.

---

## Plano 1 · Enganche — 0,0 a 1,4 s

| | |
|---|---|
| **Qué se ve** | La pantalla de Yala IA en reposo, con los chips de sugerencia |
| **Qué hace la Capa B** | `AppleTitle`: «Un gasto, en una frase» / «One expense, one sentence» |
| **Energía** | Quieta. Entra con spring y se va antes de que empiece el tipeo |
| **Por qué ahí** | El rótulo se sienta en la banda libre bajo los chips (y≈1005). No los tapa: los chips terminan en y≈897 |
| **Regla** | Máximo 6 palabras. El hook dice la promesa, no la explica |

## Plano 2 · La frase — 1,4 a 5,8 s

| | |
|---|---|
| **Qué se ve** | El tipeo y la burbuja: «Registra un gasto de 20 soles en restaurantes con concepto Pizza» |
| **Qué hace la Capa B** | **Nada.** Silencio de rótulos |
| **Energía** | Sube sola: el texto apareciendo ya es el movimiento |
| **Por qué ahí** | Es el momento en que se entiende el producto. Un rótulo encima compite con lo único que importa leer |

## Plano 3 · El resultado — 5,8 a 11,3 s

| | |
|---|---|
| **Qué se ve** | Card de confirmación → selector de cuenta → «Gastos Soles · PEN» → Guardar |
| **Qué hace la Capa B** | Nada. La card ocupa el 27 %–73 % de la pantalla y **no se tapa** |
| **Energía** | La del producto. Los sheets de iOS ya traen su propio movimiento |
| **Nota** | Aquí se ve que la subcategoría «Alimentación · Restaurantes» **la puso la IA sola**. Es la prueba de la afirmación del plano 4 |

## Plano 4 · El remate — 11,3 a 17,2 s

| | |
|---|---|
| **Qué se ve** | «Pizza · PEN 20.00 · ✅ Registrado», luego la lista de Registros |
| **Qué hace la Capa B** | `Callout` rosa: «La categoría, puesta sola» (11,9–13,9 s) → `EndCard` con el wordmark |
| **Energía** | Baja y cierra |
| **Por qué en 11,9 y no en 11,3** | El callout entra **medio segundo después** de que la fila de éxito aparezca. Si entra a la vez, parece que lo anuncia; entrando después, lo confirma |
| **Por qué ahí** | Cae en y≈1145 del lienzo: por debajo del contenido del chat (acaba en y≈825) y por encima de la barra de escritura (y≈1337). Medido sobre el render, no supuesto — la primera versión pisaba la barra |

---

## Lo que este piloto NO demuestra

- **No demuestra el look 2.1.** La toma es tema Light; el pack es Liquid Glass oscuro.
- **No demuestra una toma limpia.** Lleva la píldora roja de grabación, tapada con
  `crop: { top: 0.05 }`.
- **No está lista para publicar.** Los datos de la pantalla parecen reales. Ver
  `OPERACION.md § Deuda de la toma piloto`.

Lo que sí demuestra es que **el sistema funciona de punta a punta**: footage real → props →
dos lienzos → dos mp4 verificados.
