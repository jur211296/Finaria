---
id: ipad-native-app
status: backlog
priority: medium
area: platform
created: 2026-09-09
source: idea Jürgen 2026-09-09
---

# App nativa para iPad

## La idea

Una versión de Yala pensada para iPad, no la de iPhone estirada: aprovechar el ancho para ver el
detalle y el contexto a la vez.

## Por qué importa

Las finanzas se revisan sentado. El iPad es donde el usuario compara meses, cuadra cuentas y mira
informes largos — todo lo que en el teléfono obliga a ir y volver entre pantallas.

## Estado

Idea capturada, **sin spec**. Nota de camino, medida el 2026-09-09: la app **ya tiene rastro de
iPad** —el helper de Design System `DS.Adaptive.sheetDetents(_:)`
(`Yala/App/Theme/DesignTokens.swift:436`) existe para adaptar sheets a iPad/Mac, y hay ramas `isWide`
en las vistas de Estadísticas—, así que el punto de partida no es cero. Al hacer spec, medir qué
parte está ya adaptada antes de estimar.

## Relacionados

- [[iphone-duo-native-app]] y [[apple-watch]] — la misma tanda de plataformas del 2026-09-09.
- [[yala-android]] — la otra plataforma pendiente.
