---
name: bisect-de-un-flaky-miente
description: Bisecar un rojo no determinista produce correlaciones falsas convincentes — 4/6 con cambios contra 0/2 sin ellos, todo azar. Lo que zanja no es otra muestra: es la muestra IMPOSIBLE, un mutante inerte que falla igual. Y el rojo que se muda de test lo confirma gratis.
metadata:
  type: feedback
---

**Cuando el rojo que biseco no es determinista, el bisect me da una respuesta clara y equivocada.** La
salida no es tomar más muestras: es **buscar la muestra que no puede tener causa**.

**Why:** el 2026-09-07, en `welcome-privacy-branch-has-no-secondary-door`, la suite XCUITest completa
acabó con un rojo en `QuickActionsFavoritesUITests` («no apareció la pantalla de éxito de la
transacción»). Bisequé contra el árbol base y salió una correlación preciosa:

| Árbol | Fallos |
|---|---|
| Base | 0/2 |
| Mío completo | 2/4 |
| Mitad A (2 ficheros) | 1/1 |
| **Solo `OnboardingStepPlan.swift`** | **1/1** |

Iba camino de perseguir el diff. Lo que la salvó fue mirar QUÉ era ese último cambio: **un parámetro
nuevo con default `false` que el call-site de esa versión ni siquiera pasaba.** El `Set` resultante
era idéntico y ningún camino de ejecución cambiaba. Un fallo sin causa posible en el código prueba
que el instrumento tiene ruido — y con eso, la tasa 2/4 del árbol completo deja de significar nada
frente al 0/2 del base.

La confirmación llegó gratis en la corrida siguiente: **el rojo se mudó de test**
(`EdgeCasesUITests.test_extremeMinimumAmountSaves`), mismo aserto y misma línea, con el anterior
pasando. Un defecto de código no cambia de víctima entre corridas del mismo commit.

**How to apply:**

- **Antes de creer un bisect, pregúntate si la muestra que acusa PUEDE causar el síntoma.** Si el
  cambio es inerte —un default que nadie pasa, un comentario, un rename privado— el bisect está
  midiendo azar y hay que parar ahí. Es más barato que diez muestras más.
- **Dos señales de flake que se leen sin estadística:** el rojo cambia de test entre corridas, y **las
  corridas que FALLAN tardan MENOS que las que pasan** (una espera interna se rinde y el caso acaba
  antes). Si el que falla es el lento, entonces sí es presupuesto.
- **Busca un reproductor corto antes de tomar muestras.** Aquí, en vez de 37 min por muestra, corrí las
  cuatro suites que preceden a la víctima en el orden alfabético más la suya: **3 minutos** y ~50 % de
  fallo. Ese reproductor vale más que el diagnóstico y va en el ticket.
- **Y no lo descartes por ser flaky.** Este mismo aserto ya cazó una rotura REAL (el `.alert` con label
  dinámico, `.claude/rules/swiftui-ds.md`), y su síntoma cae en pantallas sin relación con el cambio.
  El resultado correcto es un ticket con la medición y el reproductor, no un encogimiento de hombros.
- **Revertir para bisecar se hace con `cp` desde copias propias**, nunca con `git checkout --` en árbol
  sucio ([[revertir-sin-commit-destruye]]), y `git show HEAD:<path> > <path>` para traer la versión base.

Relacionado: [[rojo-conocido-no-exime-de-bisecar]] (el error inverso: dar por ajeno un rojo que era
mío) · [[el-arbol-base-contesta-si-es-mio]] (el bisect que SÍ funciona, cuando el rojo es
determinista) · [[mutante-compilado-zanja-hipotesis]].
