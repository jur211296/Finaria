# Guion Device-QA eficiente: cluster de tickets relacionados, paso a paso — Jürgen prueba, Claude solo registra

## Contexto
Jürgen 2026-09-09: paralelo a la cola high. TestFlight **build 13** (v2.1) ya VALID en grupo interno («Test interno»). PR #116 mergeado.

Dos móviles:
1. **Personal** — TestFlight, tu Apple ID (grupo interno → ve build 13).
2. **Solo QA** — TestFlight. Si no es el mismo Apple ID, puede NO ver el 13 (grupo externo aún en READY_FOR_BETA_SUBMISSION). Incluye en el guion la config inicial de cada uno y el chequeo de build instalado.

## Que se pide
1. Elige un **cluster** de tickets en `tickets/qa/` relacionados (p.ej. grupos multi-device, o invite/join/leave, o notifs APNs — lo que más tickets cierre por minuto de prueba). Prioriza high/bloqueados por device.
2. Arma el **guion más eficiente posible**: setup inicial de cada móvil → secuencia de pasos que maximice tickets cerrados por gesto. Sin Excel ni tablas para Jürgen: pasos cortos numerados que le digas en chat (vía Frank/webhook).
3. Flujo: tú das el siguiente paso → Jürgen contesta qué vio (PASS/FAIL/bloqueado) → **solo registras** (board, `## QA Visual`, capturas si él manda, `docs/TICKETS.md`). No inventes PASS.
4. Config inicial explícita: TF build 13, cuentas/Apple IDs, onboarding, permisos notificaciones, etc.
5. Al final: tabla ticket · veredicto · qué queda para otra tanda.

## MODO AUTÓNOMO EN REGISTRO
Actualiza board al cerrar cada veredicto. Bugs nuevos → ticket. `/cerrar-total` cuando el lote del cluster esté agotado o Jürgen diga basta. Decisiones de producto → pregunta en sesión (Frank avisa).

## Que NO hay que tocar
- marketing/, clinicas-dentales-bi.
- No subas otro TF salvo que el 13 esté roto y Jürgen lo pida.
- No generes Excel/CSV para Jürgen.

## Como se sabe que esta bien
- Guion ejecutado o listo con pasos claros; board al día; resumen de cuántos QA bajaron; `/cerrar-total` o idle con «siguiente paso» claro para Jürgen.

## Avisos al bot dueño (Frank)
POSTea cuando: (1) decisión/acceso; (2) PR; (3) /cerrar-total con resumen; (4) **siguiente paso del guion listo para Jürgen** o sin siguiente — una vez por tramo.
NO avises por ruido de build/CI.
