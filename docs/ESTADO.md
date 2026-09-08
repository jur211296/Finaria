---
updated: 2026-09-08
tags: [now, punto-de-retomada]
---

# NOW — 2026-09-08 (Lima)

**Rama** `2.1` · HEAD `cd4cc381` — docs(ticket): la latencia no degrada — el rojo apunta al corpus de tes
TestFlight build **12** (CPV 12). **Subida Yala (TF/store) = solo Mini.**

## Esta sesión

**Las cinco decisiones que llevaban semanas quietas están contestadas, y las tres que llevaban código
están dentro** (PR #100 y #101): el dueño de grupo atrapado ya ve la salida de Archivar; el
recordatorio de deudas llega a quien acepta avisos, y su interruptor ya no se puede encender si los
avisos de Grupos están apagados; y el «≈» solo sale cuando lo aproximado pesa un 5 % de su lado.

**Y las tres migraciones que staging arrastraba desde el 4-sep están aplicadas y verificadas por
md5.** Staging quedó byte a byte igual que producción; la bomba del dead-letter del presupuesto está
desarmada. Se destrabó dando acceso al proyecto de staging por el conector — el único bloqueo real.

**Dos cosas que conviene no olvidar de cómo salió.** La review adversarial se lanzó con los 6448
tests en verde y encontró una regresión mía: el «Disponible» perdía el «≈» justo cuando la
incertidumbre era 49 veces mayor que el número. Y el fichero nuevo citaba a `FXPnLLogic` como modelo
mientras hacía lo contrario que él.

## Abiertos

1. **`goldens-de-staging-solo-pasan-a-trozos`** — los 25 goldens dan 14-15/25 en tres corridas
   completas. Todos los fallos son timeouts, **cero aserciones**: no hay fallo de lógica. Cuatro
   hipótesis probadas y caídas (migraciones, solapamiento, volumen en BD, manifest desincronizado).
   El ticket deja la siguiente medición escrita: instrumentar `pull()` y contar viajes, porque a
   130 ms por petición un test de 55 s hace ~400. Sospechoso: los 677 grupos acumulados de `jwtA`.
2. **Device-QA** de lo de hoy (dueño atrapado, recordatorio, «≈»). El del «≈» **no es simulable**:
   ningún seed es multi-divisa.
3. **DMARC el 15-sep** · **cobertura de UI el 22-sep**. Los dos esperan al calendario, no a nadie.

## Siguiente

Explicar el rojo de los goldens. Hasta entonces **el Worker no se despliega** — decisión de Jürgen
del 8-sep, pese a que ya no hay bloqueo técnico: `wrangler` está autenticado y los dos commits que
lo frenaban están mergeados en `2.1` desde el 3-sep.

## Bloqueo

Ninguno que dependa de Jürgen. El deploy del Worker está en pausa por decisión suya, no por acceso.
