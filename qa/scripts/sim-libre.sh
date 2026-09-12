#!/bin/bash
# ¿Está el simulador libre para correr XCUITest?
#
# Dos corridas de XCUITest sobre el MISMO simulador se derriban entre sí: comparten
# bundle id, así que el runner de la segunda mata al de la primera a media ejecución.
# El síntoma NO se parece a un fallo de test — es «Restarting after unexpected exit»,
# exit 65 y casos en «Failing tests» que nunca imprimieron una línea de fallo.
# Medido el 2026-09-07; detalle en `.claude/rules/testing.md`.
#
# **Preguntar UNA vez no basta, y eso costó un ticket `high` falso (2026-09-11).** Esta
# comprobación caduca en el instante siguiente: una corrida de XCUITest dura entre 3 y 40
# minutos, en esta máquina conviven ~14 worktrees y todos apuntan al mismo simulador, así
# que la ventana para que otra sesión entre a mitad es la corrida entera. Cuando eso pasa,
# el veredicto de la primera NO vale — y no siempre se nota: además del «Restarting after
# unexpected exit» de arriba, la otra corrida INSTALA su .app sobre el mismo bundle id, y
# a partir de ahí la primera tapea un binario que no es el suyo. Eso da rojos con su línea
# de fallo y su mensaje de aserto, indistinguibles de un rojo de test.
#
# Uso:  bash qa/scripts/sim-libre.sh              → informa y sale 1 si está ocupado
#       bash qa/scripts/sim-libre.sh --quiet      → solo el exit code
#       bash qa/scripts/sim-libre.sh --vigilar PID → centinela: vigila mientras viva PID
#                                                    (el xcodebuild de la corrida) y dice
#                                                    al final si estuviste solo
#
# Exit: 0 = libre / estuviste solo · 1 = hay (o hubo) otra corrida de test

QUIET=0
[ "$1" = "--quiet" ] && QUIET=1
say() { [ "$QUIET" -eq 1 ] || echo "$@"; }

# ¿Qué PIDs de `xcodebuild` están EJECUTANDO tests ahora mismo?
# `pgrep -x` para no cazar los ~91 falsos positivos de `pgrep -f xcodebuild` (cualquier
# shell que lo mencione). `build-for-testing` no cuenta: compila, no instala ni lanza.
pids_ejecutando_tests() {
  local excluir="${1:-}"
  local pid
  for pid in $(pgrep -x xcodebuild 2>/dev/null); do
    [ "$pid" = "$excluir" ] && continue
    if ps -o command= -p "$pid" 2>/dev/null | grep -qE '(^| )(test|test-without-building)( |$)'; then
      echo "$pid"
    fi
  done
}

# MARK: - Centinela (--vigilar)

if [ "$1" = "--vigilar" ]; then
  VIGILADO="$2"
  if [ -z "$VIGILADO" ]; then
    echo "uso: bash qa/scripts/sim-libre.sh --vigilar <pid del xcodebuild de tu corrida>" >&2
    exit 2
  fi

  # **Si el PID no existe, esto NO dice «estuviste solo»: dice que no vigiló nada.** Un
  # centinela que deriva su veredicto de una AUSENCIA falla ABIERTO — un typo en el PID, o
  # pasarle el del wrapper en vez del de `xcodebuild`, daría un ✓ sin haber mirado una vez.
  if ! kill -0 "$VIGILADO" 2>/dev/null; then
    echo "⛔ El PID $VIGILADO no existe: el centinela no vigiló NADA. Pasá el PID del \`xcodebuild\`" >&2
    echo "   de tu corrida (\`xcodebuild … test … & echo \$!\`), no el del shell que lo lanza." >&2
    exit 2
  fi

  INTRUSOS=""
  MAX_RUNNERS=0
  MUESTRAS=0
  # Do-while: se muestrea ANTES de comprobar si el vigilado sigue vivo, o una corrida que
  # termine entre dos muestreos saldría con cero muestras y un ✓ que no midió nada.
  while :; do
    MUESTRAS=$((MUESTRAS + 1))
    for pid in $(pids_ejecutando_tests "$VIGILADO"); do
      case " $INTRUSOS " in
        *" $pid "*) ;;
        *) INTRUSOS="$INTRUSOS $pid" ;;
      esac
    done
    R=$(pgrep -f 'UITests-Runner' 2>/dev/null | wc -l | tr -d ' ')
    [ "$R" -gt "$MAX_RUNNERS" ] && MAX_RUNNERS=$R
    kill -0 "$VIGILADO" 2>/dev/null || break
    sleep 5
  done

  # Con `parallelizable = "NO"` en las dos schemes (2026-07-24) una corrida sana tiene UN
  # runner vivo a la vez. Dos son dos corridas.
  if [ -n "$INTRUSOS" ] || [ "$MAX_RUNNERS" -gt 1 ]; then
    say "⛔ NO estuviste solo: el veredicto de esta corrida NO vale."
    [ -n "$INTRUSOS" ] && say "   otros xcodebuild ejecutando tests:$INTRUSOS"
    [ "$MAX_RUNNERS" -gt 1 ] && say "   runners de XCUITest simultáneos: $MAX_RUNNERS (lo sano es 1)"
    say ""
    say "   Repetí la corrida AISLADA antes de creerte ningún rojo — y antes de abrir un"
    say "   ticket por él. Los rojos de una corrida pisada pueden traer su línea de fallo."
    exit 1
  fi

  say "✓ Estuviste solo durante toda la corrida ($MUESTRAS muestreos, máx. $MAX_RUNNERS runner simultáneo)."
  exit 0
fi

# MARK: - Foto instantánea (modo por defecto)

OCUPADO=0
PIDS=""
for pid in $(pids_ejecutando_tests); do
  PIDS="$PIDS $pid"
  OCUPADO=1
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
