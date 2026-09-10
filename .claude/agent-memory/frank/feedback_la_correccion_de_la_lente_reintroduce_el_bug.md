---
name: la-correccion-de-la-lente-reintroduce-el-bug
description: Aplicar el arreglo que una lente propone sin volver a recorrer la población entera puede devolver el bug original — me pasó el 10-sep con el predicado de iCloud, dos veces seguidas en el mismo sitio
metadata:
  type: feedback
---

**Cuando una lente adversarial dice «el predicado X está mal, usa Y», aplicar Y no cierra el hallazgo:
hay que recorrer la población ENTERA con Y puesto.** La corrección hereda la forma del bug con la misma
facilidad que el arreglo original.

**Why:** el 2026-09-10, paso 4 del rediseño de sesiones. La lente de CloudKit cazó que el gate de la
puerta usaba `SwiftDataConfiguration.isICloudAvailable()` —`ubiquityIdentityToken`, que mide iCloud
**Drive**— y que con Drive apagado el mount `.localNoMirror` adjunta el espejo igual: el bug del ticket,
vivo, por el predicado elegido para matarlo. Su corrección era buena y la apliqué:
`personalStoreMountedDecision.attachesCloudKitMirror`, el testigo de si este arranque espeja.

Y ese término devuelve **`false` para `.neutralNoMirror`**, que es el mount de toda instalación fresca —
o sea el 100 % de la población de la puerta. La corrección apagaba la validación justo en el caso
principal del ticket. Lo encontré yo releyendo el flujo entero, no la lente: ella había mirado el
predicado, no a quién se le aplica.

Dos preguntas parecidas y un solo término para las dos, que es de donde salía el lío: «¿el espejo está
puesto AHORA?» (aviso tardío: sí, `attachesCloudKitMirror`) y «¿el iCloud de este Apple ID tiene datos
que van a acabar aquí?» (la puerta: eso solo lo contesta CloudKit).

**How to apply:**

- Tras aplicar la corrección de una lente, **evalúa el término nuevo contra cada valor del dominio**, no
  contra el caso que la lente citó. Aquí eran cinco `PersonalStoreDecision`, y el que rompía era el que
  la lente no había nombrado.
- Enuncia la pregunta que el predicado contesta **en una frase**, y comprueba que es la misma que la
  pantalla necesita. Dos preguntas parecidas comparten término hasta que una de las dos se rompe.
- El pin va en el CALL-SITE, no solo en la propiedad: mi test fija que `measure()` **no** contiene
  `mirrorWillSync`, con el control de que el camino tardío **sí** lo contiene. Un test de la propiedad
  sola habría pasado con el bug puesto.
- Y la misma pasada me encontró un segundo hueco de la misma familia: el borrado reanudado no retiraba
  su arm, así que se reanudaba en cada arranque. Ninguna lente lo vio — lo introduje yo al unificar los
  dos caminos DESPUÉS de que las lentes leyeran el diff. **Lo que se escribe después de la review no
  está revisado**, aunque lo haya escrito la review.

Relacionado: [[lentes-adversariales-se-contradicen]], [[mi-fix-hereda-la-forma-del-bug]],
[[el-prefiltro-tapa-al-criterio]] — este caso es literalmente un pre-filtro tapando al criterio, puesto
por la corrección de un pre-filtro que tapaba al criterio.
