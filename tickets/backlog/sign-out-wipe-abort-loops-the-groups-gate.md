---
id: sign-out-wipe-abort-loops-the-groups-gate
status: backlog
priority: medium
area: "modo-nube, groups"
created: 2026-09-11
source: "review adversarial de la mitad 2 del paso 5 (`groups-entry-on-a-mirrored-store-still-blocks-the-owner`), lente de pérdida de datos"
---

# Si el borrado de arranque no puede borrar los archivos, la puerta de Grupos entra en bucle

## Lo medido (2026-09-11)

`SwiftDataConfiguration.performSignOutWipeIfArmed` aborta (guard S3) cuando `deleteFiles` falla por algo
que no es «no existe», y desde el paso 9 **con el modo en `.icloud` DESARMA** en vez de reintentar — que es
lo correcto: con el espejo montado, un reintento tardío se llevaría cambios que nadie esperó a exportar.

El problema es lo que pasa después, cuando quien armó fue la puerta de Grupos:

1. El wipe aborta y desarma. Los archivos siguen ahí; `hasCompletedOnboarding` sigue `false`.
2. `presentNextOnboardingScreen` consume el destino pendiente `.groupsOrganizer` y abre el Welcome en la
   puerta.
3. La puerta re-mide: los datos siguen y el espejo también ⇒ vuelta al neutro ⇒ arma ⇒ persiste el destino
   ⇒ pantalla «reabre Yala» ⇒ el arranque siguiente vuelve al paso 1.

Cada vuelta corre además `clearLocalSurfacesForArmedWipe`, que cancela **todas** las notificaciones locales
y vacía la caché del widget. Los datos sobreviven —el borrado falló— pero la app queda dando vueltas.

## Por qué no se arregló en el PR que lo encontró

No hay señal que distinga «este arranque viene de un S3» de «este arranque es el primero»: el arm se
desarmó y los datos siguen, que es exactamente el estado de partida. Inventar esa señal es una superficie
durable nueva, y el disparador (un fallo de borrado persistente: permisos, disco, un archivo bloqueado) no
es el caso común.

## Por dónde va

- Un testigo one-shot que el abort S3 deje puesto, y que la puerta lea para enseñar una pantalla honesta
  («no pudimos preparar este teléfono») en vez de reintentar.
- O que el destino pendiente no se re-persista cuando el arranque anterior ya lo consumió sin resultado.

## Criterios de aceptación

- [ ] Con `deleteFiles` fallando siempre, la puerta de Grupos deja de reintentar tras el primer intento y
      lo dice.
- [ ] Las notificaciones locales no se cancelan en cada vuelta.
- [ ] El camino normal (borrado que sí funciona) no cambia.
