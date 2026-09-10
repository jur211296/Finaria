---
id: after-session-redesign-review-widgets-siri-applepay-and-web-copy
status: backlog
priority: medium
area: "widgets, intents, web, marketing"
created: 2026-09-09
source: "ADR 2026-09-09 «Sesiones — dos ejes» — consecuencias; pedido por Jürgen para DESPUÉS del rediseño"
---

# Después del rediseño de sesiones: revisar widgets, Siri, Apple Pay, notificaciones y todos los textos de la web

## Qué es esto

Una lista de comprobación **posterior** a implementar el ADR de sesiones (últimos tickets:
`shell-derives-from-two-session-axes`). Jürgen pidió dejarlo anotado y no mezclarlo con el rediseño.
Nada de aquí se ha medido todavía; cada punto empieza por medir.

## Dentro del repo (Frank)

- [ ] **Widgets** (`YalaWidgets/`, DTO del App Group): qué enseñan en la celda «sin privada + nube solo
      grupos» (no hay Panel) y en «nube completa» (¿la caché sobrevive al cierre de sesión? ¿se vacía con
      el wipe local?). El ticket descartado `widget-snapshot-visitor-overwrites-owner` describía el
      síntoma para la visita; el hecho de fondo —la caché del widget no sabe de sesiones— sigue vivo.
- [ ] **Siri** y **Apple Pay** (cola en App Group, `Yala/App/Intents`): qué pasa con una entrada en cola
      cuando la sesión activa es solo-grupos, o cuando se cerró sesión entre el intent y el drenaje.
- [ ] **Notificaciones** de informes y recordatorios (`ReportNotificationService`, pagos planificados):
      que no programen nada sin finanzas personales, y que el cierre de sesión las cancele.
- [ ] **Exportación** (`ExportWizard`): qué exporta cada celda.
- [ ] `qa/coverage-index.json`: áreas nuevas por celda de sesión.

## Fuera del territorio de Frank (Lola — `marketing/` y `Web/`)

- [ ] La web, la FAQ, la política de privacidad y los términos dicen que los datos de Grupos viajan
      «por iCloud, no por servidores nuestros» vía CloudKit Sharing (revisión web del 2026-09-03, L2,
      `Web/REVISION-WEB-UX-A11Y-2026-09-03.md:95`). Con el ADR la historia es «Grupos = cuenta en la
      nube (Google/Apple), en el backend de Yala». Hay que reescribir esas cuatro superficies.
- [ ] Ficha de la App Store (7 idiomas) y capturas: la elección privado / nube y la mini-app de Grupos
      como se ve al terminar el rediseño.
- [ ] Etiquetas de privacidad de App Store Connect: comprobar que declaran lo que la cuenta en la nube
      recoge (probablemente ya, desde el Modo Nube; medir).

## Cuándo

Después de que `shell-derives-from-two-session-axes` esté en `2.1`. No antes: cualquier medición
anterior describiría una app que va a cambiar.
