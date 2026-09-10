---
id: coverage-index-meta-counts-drifted-from-reality
status: backlog
priority: low
area: "qa, proceso"
created: 2026-09-10
source: "review adversarial del paso 4, lente de tests"
---

# El `_meta.counts.total` del índice de QA dice 134 y hay 139 áreas

## Lo medido (2026-09-10)

`qa/coverage-index.json` declara `_meta.counts.total: 134`; el array `areas` tiene **139** entradas.
`bash qa/validate-coverage.sh` sale `RESULT: OK` porque **no comprueba ese campo**: valida el ratchet del
backlog determinista y los `scenarioIDs`, nada más.

## Por qué importa aunque hoy no rompa nada

Es un número que nadie recalcula y que cualquiera puede citar. Es la familia del «conteo de un informe
que en realidad era un valor POST-commit» de `CLAUDE.md`: una cifra escrita que envejece sin avisar y que
la próxima sesión reusa como si fuera medida.

## Por dónde va el arreglo

O el validador lo recalcula y falla si diverge, o el campo se borra. **Recalcularlo a mano no vale**:
volvería a divergir en el primer área nueva.

## Criterios de aceptación

- [ ] `_meta.counts` se deriva del contenido, o no existe.
- [ ] `validate-coverage.sh` falla si alguien lo deja a mano y diverge.
