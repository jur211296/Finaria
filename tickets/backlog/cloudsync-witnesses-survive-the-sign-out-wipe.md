---
id: cloudsync-witnesses-survive-the-sign-out-wipe
status: backlog
priority: low
area: "modo-nube, settings"
created: 2026-09-11
source: "review adversarial del plan del paso 9 (`session-exits-one-verb-per-session`)"
---

# Auditar los testigos `cloudSync.*` que sobreviven al borrado de cierre de sesión

`DataWipeService.removeUserPreferenceKeys` excluye el prefijo `cloudSync.*` a propósito: esas claves las
gestiona el boot-wipe en su orden kill-safe. Desde el paso 9 ese boot-wipe cierra también sesiones
PRIVADAS, y un testigo de la vida que se cierra que sobreviva decide cosas de la siguiente. El paso 9
retiró los dos que encontró (`groupsOnlyNeutralMount` ya estaba; `privateChoseWithoutICloud` es nuevo).

## Qué hacer

Recorrer todas las claves `cloudSync.*` y clasificarlas: de la instalación (se quedan), de la vida que se
cierra (el hook las borra) o de la cuenta (no aplican). Un test por clase.
