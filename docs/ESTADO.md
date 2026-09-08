---
updated: 2026-09-08
tags: [now, punto-de-retomada]
---

# NOW — 2026-09-08 (Lima)

**Rama** `2.1` · HEAD `62880911` — Merge #106: el borrador del chat deja de contradecirse
TestFlight build **12** (CPV 12). **Subida Yala (TF/store) = solo Mini.**

## Esta sesión

**El borrador del chat ya no nace gasto con subcategoría de ingreso** (PR #106). Esa combinación
entraba como «ingreso negativo»: restaba del total de ingresos mientras el widget de inicio la
sumaba. Decidido y escrito en el código: **manda el tipo del borrador**, que es lo que ya asumían los
otros cuatro puntos del chat. El ticket señalaba un sitio y el patrón tenía **seis**; entraron los
tres que la firma del helper obliga a tocar —y en Siri destapó que «solo gastos» forzaba el tipo
DESPUÉS de elegir la subcategoría, así que fallaba incluso por la vía buena—. Los otros tres van en
ticket. 13 tests con control positivo, 4 mutantes compilados, suite completa 6487/6487 en local.

**Dos huecos de proceso**, medidos de camino y con ticket cada uno: el candado de ADR-013 no corre
aquí (`core.hooksPath` local sustituye al global, así que nada revisa el mensaje de un commit), y
`/gate` replica uno de los dos pasos del job `coverage-index` — dio verde a lo que el CI tumbó en
17 s, y con la regla del 1-sep eso aterriza directo en `2.1` sin PR que lo pare.

## Abiertos

1. **Device-QA** acumulado, ya son cinco: dueño atrapado, recordatorio, «≈» (**no** simulable), el
   signo del chat de #102, el barrido de #103 y el de hoy. Los tres últimos **sí** son simulables;
   el de hoy pide sembrar la memoria de un comercio (aprobar 5 ingresos con la misma nota) y dictar
   después un gasto con ella.
2. **DMARC el 15-sep** · **cobertura de UI el 22-sep**. Esperan al calendario, no a nadie.

## Siguiente

El device-QA, que cierra tres de golpe.

## Bloqueo

**Tres decisiones tuyas.** La nueva y más urgente: `el-hook-que-prohibe-atribuir-a-una-ia-no-corre-en-este-repo`
(high) — cuatro caminos dentro, y toca infraestructura común a todos los agentes. Siguen
`corpus-de-test-de-staging-crece-sin-limite` (el golden más ajustado cae en unas 35 corridas) y, sin
prisa, si el filtro de naturaleza debe subir a `MerchantMemoryService`, que es un sitio con seis
llamadores.

El deploy del Worker sigue en pausa por decisión del 8-sep, no por acceso.
