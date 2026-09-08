---
id: dmarc-sube-la-politica-tras-observar
status: backlog
priority: medium
area: web, dns
created: 2026-09-08
updated: 2026-09-08
source: seguimiento de web-domain-has-no-spf-dkim-dmarc, cerrado el 2026-09-08
---

# DMARC está en `p=none`: observa quién suplanta el dominio, pero no lo impide

## Qué pasa

Desde el 2026-09-08 `yala-app.pe` autentica su correo: SPF, DKIM y DMARC en `pass`, verificado con
un correo real (ver `tickets/done/web-domain-has-no-spf-dkim-dmarc.md`). Pero la política quedó en
**`p=none`**, que es lo correcto para empezar y **no protege a nadie**:

    v=DMARC1; p=none; rua=mailto:admin@yala-app.pe

`p=none` significa «apunta lo que veas y entrega igual». Un correo falsificado como `@yala-app.pe`
hoy **sigue llegando** a la bandeja del usuario; la diferencia con antes es que ahora aparece en un
informe. La protección real empieza en `p=quarantine` y se completa en `p=reject`.

## Por qué no se sube ya

Porque subir la política sin haber leído los informes es exactamente como se tira correo legítimo
propio. El `rua` lleva a `admin@yala-app.pe` y todavía **no ha llegado ningún informe**: los
generadores (Google, Microsoft, Yahoo…) los mandan **una vez al día**, así que el primero llega
~24 h después de publicar, y hacen falta varios para distinguir un remitente legítimo olvidado de
un suplantador.

Lo MEDIDO en el ticket padre acota bastante el riesgo: en el repo no hay proveedor de envío, la web
no manda correo y ningún subdominio tiene MX, así que el único remitente **conocido** es Google
Workspace. Pero «conocido» no es «único»: un servicio de terceros configurado desde el navegador
—facturación, formularios, un boletín— no deja rastro en el repo y es justo lo que los informes
sacan a la luz.

## Qué hacer, y cuándo

1. **A partir del 2026-09-15** (una semana de informes), abrir los `rua` que hayan llegado a
   `admin@`. Son XML comprimidos; cualquier visor de DMARC los lee.
2. **Comprobar que todo lo que aparece con `pass` es nuestro** y que nada legítimo sale con `fail`.
   Si aparece un remitente legítimo que no es Workspace, primero se le añade al SPF (o se le pone
   DKIM), y solo después se sube la política.
3. **Subir a `p=quarantine`** —el sospechoso va a spam, no se pierde— y dejarlo otras 1-2 semanas.
4. **Subir a `p=reject`** cuando dos semanas de informes no traigan sorpresas.

El procedimiento de edición del registro, con las trampas del panel, está en el ticket padre; aquí
solo cambia el valor del TXT `_dmarc`.

## Cómo se sabe que está bien

`dig +short TXT _dmarc.yala-app.pe @ns.rcp.net.pe` devuelve la política nueva, y un correo de
comprobación sigue dando los tres `pass` (subir la política no debe romper el propio correo — si lo
rompe, es que algo legítimo no estaba autenticando y el informe lo decía).

## Lo que NO hay que hacer

- **Saltar `quarantine` e ir directo a `reject`.** El escalón intermedio manda a spam en vez de
  descartar: si nos equivocamos, el correo se recupera de la carpeta de spam en vez de perderse.
- **Subir la política sin haber abierto un solo informe.** Es el error que este ticket existe para
  evitar; el ticket padre ya lo dejaba escrito como «después, no ahora».
