---
name: dns-yala-app-pe
description: Dónde se administra el DNS de yala-app.pe, quién puede entrar, y el estado de autenticación de correo re-medido el 2026-09-08 (el ticket quedó en blocked, con checklist pegable)
metadata:
  type: reference
---

# DNS de yala-app.pe — dónde se toca y quién puede

**Registrador:** NIC.PE / punto.pe. **Zona autoritativa:** servidores de la RCP
(`ns.rcp.net.pe` 161.132.17.10, `ns2.rcp.net.pe` 209.45.127.3).
**Correo:** Google Workspace (MX a ASPMX.L.GOOGLE.COM + ALT1-4). **Web:** Vercel (A 216.198.79.1).

**No hay nada en el repo sobre esto** — ni ticket, ni doc, ni ADR (comprobado 2026-09-03).
Este fichero es el único puntero.

## Lo que yo no puedo hacer aquí

Los dos paneles (consola de Workspace y panel DNS del registrador) exigen autenticarse, y yo no
introduzco credenciales ni entro en cuentas. **Los cambios de DNS y de Workspace los teclea
Jürgen**; lo mío es medir con `dig`, dar los valores exactos y verificar después.

## Estado re-medido el 2026-09-08 (CADUCA — re-medir con dig antes de citarlo)

Sin SPF, sin DMARC (`_dmarc` daba NXDOMAIN), sin DKIM en ninguno de 20 selectores probados.
El único remitente de `@yala-app.pe` es Google Workspace — confirmado por Jürgen y coherente con
el repo: no hay proveedor de envío, el gateway no manda correo, y `admin@yala-app.pe` solo aparece
como `mailto:` en la web (eso envía desde el cliente del visitante, no desde el dominio).
Buzón elegido para los informes DMARC: `admin@yala-app.pe`.

**El serial del SOA es el testigo barato de si un cambio entró**: hoy `2026071400` (14 de julio, la
zona no se toca desde entonces). Si tras pegar en el panel el serial no ha cambiado, el panel no
guardó — y eso se confunde con «aún no ha propagado», que es una espera inútil de dos horas.

**El trabajo de preparación está hecho y el ticket está en `tickets/blocked/`**: lleva el checklist
con el host y el valor exactos, el orden (generar la firma → publicar los tres TXT → activar) y las
trampas. Lo que falta es que Jürgen se autentique y pegue; nada más se puede adelantar.

## Dos trampas de esta zona en concreto

1. ~~`ns2.rcp.net.pe` no respondía~~ — **CORREGIDO el 2026-09-08: sí responde.** 6/6 autoritativas,
   2 ms, con el mismo serial que `ns.` (zona sincronizada) y delegación coherente en el TLD. Lo del
   2026-09-03 (3/3 timeouts) fue transitorio o una ruta, y ya da igual cuál: **no hay punto único de
   fallo y no hay nada que reportarle a la RCP.** Lo dejo escrito porque el dato viejo estaba en el
   ticket y en esta ficha, y era de los que se citan sin volver a medir.
2. **Caché negativa de 2 h.** SOA `7200 300 604800 7200`: un nombre que hoy es NXDOMAIN sigue
   siéndolo para los resolvers hasta 2 h después de crearlo. Verificar contra el autoritativo
   (`dig ... @ns.rcp.net.pe`) para saltarse la espera, y usar el serial del SOA para confirmar que
   el cambio entró.

Ver también [[decisiones-que-esperan-a-jurgen]].
