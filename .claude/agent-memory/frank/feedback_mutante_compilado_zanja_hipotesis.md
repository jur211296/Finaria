---
name: mutante-compilado-zanja-hipotesis
description: Cuando un ticket declara que no hay dato para elegir entre hipótesis, compilar el código ANTERIOR y reproducir en simulador es ese dato — y es barato
metadata:
  type: feedback
---

Cuando un ticket dice «no hay dato que distinga la hipótesis 1 de la 2, y esa distinción decide dónde
va el fix», **el dato se fabrica**: se compila el código anterior (mutante) y se reproduce el
recorrido en el simulador. No hace falta el device ni una traza del usuario.

**Why:** el 2026-09-05, `groups-deleted-group-detail-stays-open` traía un AC explícito de «antes de
tocar código, anota QUÉ pantalla se quedó abierta — sin eso el fix se elige a ciegas», y declaraba las
tres hipótesis irresolubles porque del device solo había el relato del owner. Un mutante compilado
(quitar la rama del fix) más seis taps en el simulador reprodujeron el fallo **exacto** y zanjaron que
era el detalle en push, no la sheet. Coste: un rebuild incremental de 30 s. El ticket llevaba desde el
28-ago parado por esa pregunta.

**How to apply:** en cualquier bug de **presentación o navegación** —qué pantalla queda, qué se cierra,
qué queda debajo— donde los tests unitarios no puedan pronunciarse. La secuencia que funciona:
1. Implementar el fix y dejarlo verde.
2. Aplicar el mutante y **volver a compilar** (no basta el mutante en tests: el bug es de UI).
3. Repetir el MISMO recorrido y capturar las dos pantallas.
4. Revertir con `cp` desde una copia previa — nunca `git checkout --` en árbol sucio, ver
   [[revertir-sin-commit-destruye]].

Vale igual como control positivo de un `MUTANTE VERIFICADO` escrito en `qa/coverage-index.json`: esa
frase es una afirmación medible y hay que medirla, no inferirla. Relacionado:
[[mis-mediciones-fallan-por-el-filtro]].

**Trampa del seed al montar el caso:** el botón de borrar un grupo se deshabilita si CUALQUIER miembro
tiene deuda, no solo tú. Con `-uitest-seed grupos-saldado`, el grupo de 3 miembros sale deshabilitado
(deuda entre los otros dos) y el de 2 sí es borrable. Si el botón no aparece tappable, mira el hint de
deuda antes de dudar del build.
