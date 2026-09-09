---
id: ci-avisador-de-rojos-advisory-tiene-la-clave-mal
status: backlog
priority: high
area: "ci, observabilidad"
created: 2026-09-08
source: run 34309857537 del PR #110 (2026-09-08)
---

# El avisador de rojos advisory del CI no puede avisar: `Invalid API key`

## Qué pasa

El job `tests` de `.github/workflows/qa.yml` corre sus pasos de test como **advisory**
(`continue-on-error`), y para que un rojo no pase inadvertido tiene un paso final —«Avisar a Grok si
algun paso advisory fallo»— que manda el aviso al webhook. Ese paso **no puede mandar nada**:

```
CI de jur211296/Yala (110/merge): hay pasos de test en ROJO que el run marca como verde.
Pasos en rojo:
- Unit tests (pure-logic)
##[error]Nadie se ha enterado de que hay tests en rojo.
{"code":"error","message":"Invalid API key"}
##[error]Process completed with exit code 1.
```

El `SENDER_KEY` del secreto del repo no es válido para el webhook. El paso lo detecta y sale con
`exit 1`, que es lo correcto por su parte —prefiere romper el job antes que callar—, pero el efecto
neto es que **el aviso no llega a nadie** y el job entero se pone rojo por un fallo de credencial, no
por los tests.

## Por qué es `high` pese a que «el CI ya avisó»

**Porque nunca se había ejercitado y nadie lo sabía.** Medido sobre los 12 runs anteriores del
workflow: todos `success`, porque el paso de avisar solo se ejecuta cuando hay algo que avisar. El run
`34309857537` fue el primero con un paso advisory en rojo, y ahí se descubrió que la única red que
cubre a los pasos advisory llevaba puesta una llave que no abre.

Es el patrón que este repo ya pagó una vez con el guardián nocturno, que estuvo **un mes** entregando
partes a un webhook que devolvía 404. Un canal que nadie mira se muere en silencio; uno que solo se
usa en caso de incendio, también — y encima no se nota hasta el incendio.

## El daño concreto que deja mientras siga así

El diagnóstico apunta al sitio equivocado. Un `tests: fail` en un PR **no distingue** hoy entre:

- tests de verdad en rojo (lo que quieres mirar), y
- tests en verde con la credencial del avisador rota (ruido).

En este run eran **las dos cosas a la vez**: había un rojo advisory real —un source-scan de conteo— y
además la credencial estaba mal. Quien vea solo el rojo del job puede concluir «es el avisador otra
vez» y mergear encima de un test que sí fallaba, que es exactamente lo que este mecanismo existe para
impedir.

## Criterio de hecho (AC)

- [ ] Rotar `SENDER_KEY` (y comprobar `WEBHOOK_URL`) en los secretos del repo, contra el webhook que
      esté vivo hoy. **Generar y persistir en el mismo gesto**: la credencial no puede quedarse solo en
      la pantalla de quien la crea.
- [ ] **Verificar el camino entero, no la rotación.** Un `curl` de prueba contra el webhook con la
      clave nueva **desde el runner**, no desde el Mac: el secreto que falla es el del repo, y probarlo
      en local no demuestra nada.
- [ ] Un paso que ejercite el avisador **aunque no haya rojos** —un ping periódico, o el propio
      guardián nocturno— para que la próxima vez no se descubra en el incendio. Sin esto el AC anterior
      caduca sin avisar.
- [ ] Decidir si `exit 1` del avisador debe seguir tumbando el job. Hoy mezcla dos señales muy
      distintas en un solo `tests: fail`; separarlas (por ejemplo, un check propio para el aviso) haría
      el rojo legible de un vistazo.
