#!/bin/bash
# ¿Está el simulador libre para correr XCUITest?
#
# Dos corridas de XCUITest sobre el MISMO simulador se derriban entre sí: comparten
# bundle id, así que el runner de la segunda mata al de la primera a media ejecución.
# El síntoma NO se parece a un fallo de test — es «Restarting after unexpected exit»,
# exit 65 y casos en «Failing tests» que nunca imprimieron una línea de fallo.
# Medido el 2026-09-07; detalle en `.claude/rules/testing.md`.
#
# Uso:  bash qa/scripts/sim-libre.sh          → informa y sale 1 si está ocupado
#       bash qa/scripts/sim-libre.sh --quiet  → solo el exit code
#
# Exit: 0 = libre · 1 = hay otra corrida de test en curso

QUIET=0
[ "$1" = "--quiet" ] && QUIET=1
say() { [ "$QUIET" -eq 1 ] || echo "$@"; }

# xcodebuild que estén ejecutando tests. `pgrep -x` para no cazar los ~91 falsos
# positivos que da `pgrep -f xcodebuild` (cualquier shell que lo mencione).
OCUPADO=0
PIDS=""
for pid in $(pgrep -x xcodebuild 2>/dev/null); do
  # ¿es una invocación de test? (test / test-without-building / build-for-testing no cuenta)
  if ps -o command= -p "$pid" 2>/dev/null | grep -qE '(^| )(test|test-without-building)( |$)'; then
    PIDS="$PIDS $pid"
    OCUPADO=1
  fi
done

# Runners de XCUITest vivos dentro del simulador
RUNNERS=$(pgrep -f 'UITests-Runner' 2>/dev/null | wc -l | tr -d ' ')
[ "$RUNNERS" -gt 0 ] && OCUPADO=1

if [ "$OCUPADO" -eq 1 ]; then
  say "⛔ El simulador NO está libre."
  [ -n "$PIDS" ] && say "   xcodebuild ejecutando tests:$PIDS"
  for pid in $PIDS; do
    say "     └─ $(ps -o command= -p "$pid" 2>/dev/null | cut -c1-140)"
  done
  [ "$RUNNERS" -gt 0 ] && say "   runners de XCUITest vivos: $RUNNERS"
  say ""
  say "   Esperá a que termine. Correr ahora NO da un veredicto: las dos corridas"
  say "   se derriban y salen en rojo sin una sola línea de fallo real."
  exit 1
fi

say "✓ Simulador libre — ninguna otra corrida de test en curso."
exit 0
