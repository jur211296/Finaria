---
updated: 2026-09-08
tags: [now, punto-de-retomada]
---

# NOW — 2026-09-08 (Lima)

**Rama** `2.1` · HEAD `7ca6ca01` — Merge #107: el borrador del chat se guarda en la divisa de su cuenta
TestFlight build **12** (CPV 12). **Subida Yala (TF/store) = solo Mini.**

## Esta sesión

**Una transacción del chat ya no puede quedar en una divisa distinta a la de su cuenta** (PR #107).
Dictar «50 dólares» sin tener cuenta en dólares y elegir la de soles dejaba una fila en USD dentro de
una cuenta PEN: el saldo agrupa por la divisa de la transacción y convierte a la tasa de hoy, así que
esa cuenta enseñaba un número que no cuadraba y que **se movía solo**. Manda la cuenta — la regla que
el formulario ya aplicaba a ese mismo borrador; la incoherencia estaba dentro de la tarjeta, donde
«Editar» y «Guardar» hacían lo contrario. Medido: era el **único** hueco de creación de los nueve.

**El arreglo es el segundo intento, y esa es la parte que vale.** El primero derivaba la divisa en la
tarjeta y la review adversarial lo refutó: su `@Query` filtra `!isArchived` y `saveDraft` resuelve
con `context.model(for:)`, que no; con la cuenta archivada entre medias volvía el mismo bug al borde,
con un comentario al lado declarándolo imposible. Ahora la divisa **vive en el borrador**. 6 tests,
7 mutantes, y el nº5 destapó que mi propio test del borde medía después de guardar, cuando el
congelado ya lo había tapado.

## Abiertos

1. **Device-QA** acumulado, ya son seis: dueño atrapado, recordatorio, «≈» (**no** simulable), el
   signo del chat de #102, el barrido de #103, el de #106 y el de hoy. El de hoy **sí** es simulable:
   dictar en una divisa sin cuenta, elegir una local y ver que la etiqueta cambia antes de guardar.
2. **DMARC el 15-sep** · **cobertura de UI el 22-sep**. Esperan al calendario, no a nadie.

## Siguiente

El device-QA, que ya cierra cuatro de golpe.

## Bloqueo

**Cuatro decisiones tuyas.** La nueva sale del barrido de hoy:
`changing-an-account-currency-orphans-its-whole-history` (**high**) — editar la divisa de una cuenta
deja su histórico **entero** en la divisa vieja, en masa y sin aviso; de paso Yala exporta un CSV que
Yala rechaza importar. Es el hueco que queda, y es mayor que el del chat. Siguen
`el-hook-que-prohibe-atribuir-a-una-ia-no-corre-en-este-repo` (high, toca a todos los agentes),
`corpus-de-test-de-staging-crece-sin-limite` y, sin prisa, si el filtro de naturaleza debe subir a
`MerchantMemoryService`.

El deploy del Worker sigue en pausa por decisión del 8-sep, no por acceso.
