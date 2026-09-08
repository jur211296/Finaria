---
name: barrido-signo-chat
description: PR #103 — el barrido que cura los gastos del chat guardados sin signo; abierto y SIN mergear porque el daño alcanza al CSV y esa parte Jürgen no la aceptó.
metadata:
  type: project
---

**El barrido one-shot del signo del chat está hecho y en PR #103, pero el merge espera respuesta de
Jürgen.** No es un merge pendiente de trámite: hay una pregunta suya sin contestar.

**Why:** el 2026-09-08 decidió migrar a ciegas el corpus del chat acotando por fecha, y aceptó
**expresamente** un daño: «los reembolsos legítimos de esa ventana también se voltean». La review
adversarial midió que el criterio alcanza a más que eso — las filas importadas por CSV/XLSX guardan
como fecha de creación **el instante del import**, así que un fichero con años de historia importado
dentro de la ventana entra entero; y el importador reusa categorías por nombre sin mirar `isIncome`,
así que un ingreso archivado bajo «Otros» acabaría en negativo. Eso no son reembolsos, y no está
cubierto por lo que él aprobó. Ticket: `csv-import-rows-fall-in-the-chat-sign-sweep` (high), con las
tres salidas escritas. Se le avisó por el webhook (`espera-pregunta`) el 2026-09-08 15:28.

**How to apply:** si al retomar el PR #103 sigue abierto, **lo que falta es su respuesta, no trabajo**.
Míralo antes de tocar nada: si contestó «acepto igual», se mergea tal cual; si dijo «acota», el
criterio cambia y con él los tests. Si ya está mergeado, lo que queda es el **device-QA**, que es
simulable —dictar un gasto al chat, mirar el saldo antes y después del primer arranque— y el barrido
imprime en DEBUG cuántas filas curó, que es el número que nunca se pudo medir desde aquí.

Lo que NO hay que rehacer: la trampa del ancla de sync que el ticket mandaba mirar antes está
**medida y descartada** (`SyncIdentity.localAnchor` se persiste una vez, nada lo recalcula al editar,
y su único lector es el rebind del backfill de identidad). Y el gate de `!uiTestActive` **no arregla
ningún rojo** —se midió: sin él el XCUITest sigue pasando—; está para que ese verde no dependa de
ganar una carrera de 120 s.

Relacionado: [[chat-tasa-del-borrador]] (el PR #102 que lo engendró) y
[[el-prefiltro-tapa-al-criterio]], que salió de esta misma sesión.
