---
id: ci-destination-assumes-a-simulator-that-may-not-exist
status: backlog
priority: medium
area: "ci, testing"
created: 2026-09-07
source: rojo del CI en el PR #94 (2026-09-07)
---

# El CI da por hecho que el runner trae el iPhone 17 Pro, y a veces no lo trae

## Qué pasó

Corrida `34178907646` del PR #94, en el paso **Build for testing**, a los 2m30s:

```
xcodebuild: error: Unable to find a device matching the provided destination specifier:
		{ platform:iOS Simulator, OS:latest, name:iPhone 17 Pro }
	The requested device could not be found because no available devices matched the request.
	Available destinations for the "Yala Dev" scheme:
		{ platform:iOS, ... name:Any iOS Device }
		{ platform:iOS Simulator, ... name:Any iOS Simulator Device }
```

Exit 70. El job entero en rojo.

## Por qué no es un rojo del código, y cómo se comprobó

- **Tres corridas de la misma rama, minutos antes, en verde** (01:31, 01:35, 01:42) con el mismo
  destino y el mismo workflow. La de 02:06 falló.
- **El PR no toca `.github/`**: `git diff 2.1...HEAD -- .github/` sale vacío.
- El gate local corrió esos mismos tests contra el simulador real: 159 unit en 11 suites y 20
  XCUITest en 6.

⇒ es el **runner** el que a veces no trae ese simulador. Los runners de GitHub varían en los runtimes
y devices que llevan preinstalados, y el workflow no comprueba nada antes de pedirlo.

## Lo que lo hace innecesariamente frágil

Las cuatro invocaciones de `xcodebuild` del workflow (`qa.yml:277, 294, 317, 345`) fijan
`-destination 'platform=iOS Simulator,name=iPhone 17 Pro'`, y **no hay ningún paso previo** que liste
runtimes, cree el device o verifique que existe (`grep -nE "xcrun simctl|list devices|runtimes"` sobre
`qa.yml` no devuelve nada).

Y el primero de los cuatro es `build-for-testing`, que **no necesita un device concreto en absoluto**:
compilar para simulador vale con `-destination 'generic/platform=iOS Simulator'`, que es inmune a qué
traiga el runner.

## Por qué importa más de lo que parece

Los tres pasos de test son **advisory a propósito** —no bloquean—, pero el de build **no lo es**: un
rojo aquí tumba el job entero y el check del PR sale `fail`. Un rojo de infraestructura
indistinguible de un rojo real es exactamente el problema que `el-job-de-tests-del-ci-no-tiene-timeout`
acaba de arreglar por el otro extremo, y tiene el mismo final: el check se ignora, o se mergea sin
mirarlo. La primera vez que pasa se investiga; la tercera se asume que «el CI está en rojo otra vez».

## Criterio de hecho (AC)

- [ ] `build-for-testing` usa `generic/platform=iOS Simulator`: no necesita un device concreto.
- [ ] Los pasos que sí ejecutan tests resuelven el device **en tiempo de ejecución** (elegir el primero
      disponible de una lista de preferencia con `xcrun simctl list devices available`, o crearlo) en
      vez de asumir un nombre fijo.
- [ ] Si el device no se puede resolver, que el mensaje lo diga en una línea reconocible — hoy hay que
      abrir el log y leer el volcado de `xcodebuild` para distinguirlo de un test roto.
- [ ] Comprobado relanzando el job: un rojo por esta causa no debe repetirse en el reintento.
