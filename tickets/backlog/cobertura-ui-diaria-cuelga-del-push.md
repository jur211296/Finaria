---
id: cobertura-ui-diaria-cuelga-del-push
status: backlog
priority: medium
area: ci
created: 2026-09-08
updated: 2026-09-08
source: medido al cerrar `la-nocturna-de-ui-no-ha-disparado-ni-una-vez`
---

# La cobertura diaria de UI cuelga del ritmo de trabajo, no del calendario

## De dónde sale

`la-nocturna-de-ui-no-ha-disparado-ni-una-vez` (done) dejó medido que **el `schedule` de GitHub
Actions no sirve ventanas en este repositorio**: siete ventanas de un canario `*/5` en 37 minutos y
la de `qa.yml` con 7 h 53 min de margen, todas en cero, con control positivo (el canario lanzado a
mano corre en verde, así que falla el reloj y no el workflow).

La cobertura la sostiene `nocturna-vigilante.yml`, y lo hace de verdad — está verificado de punta a
punta en producción. Pero de sus dos relojes, **solo uno funciona**:

- `schedule` a las 11:43 UTC → es el mismo mecanismo que no dispara. Hoy no vale.
- `push` sobre la rama por defecto → **este es el que sostiene todo.**

## El hueco, medido

Un reloj de `push` no es un reloj diario. En los últimos 30 días hubo **8 sin ningún commit en
`2.1`**, con rachas de hasta **3 seguidos** (2026-08-19/20/21 y 2026-08-23/24/25).

```
git log origin/2.1 --since='30 days ago' --format='%cd' --date=format:'%F' | sort -u
```

En esos días no corre la suite de UI. El atenuante es real y hay que tenerlo delante antes de
gastar trabajo aquí: **un día sin commits tampoco trae código nuevo que probar**. Lo que se pierde
no es cobertura del código, es vigilancia del entorno — el tipo de rojo que aparece porque cambió
el runner, Xcode o el simulador, no porque cambiara Yala. Ese sí se detectaría tarde: el primer día
que alguien commitee, y mezclado con su propio cambio.

## La decisión (es de Jürgen)

1. **Montar un reloj que no dependa de GitHub.** Un `launchd` en la Mini que haga
   `gh workflow run qa.yml --ref 2.1` una vez al día. Es acceso suyo. Ventaja: cadencia real.
   Coste: una pieza más de infraestructura local, y depende de que la Mini esté encendida.
2. **Aceptar el hueco.** La cobertura de UI va atada al ritmo de trabajo. En un repo con esta
   cadencia es defendible, y no cuesta nada.
3. **Reintentar el `schedule` más adelante.** Si el cron vuelve a servir ventanas, el vigilante ya
   está preparado para usarlo: su `schedule` está escrito y en cuanto GitHub dispare, funciona sin
   tocar nada.

## Cómo saber si esto sigue vivo

Si el `schedule` vuelve a funcionar, este ticket se descarta solo:

```bash
gh api 'repos/jur211296/Yala/actions/runs?event=schedule&per_page=100' --jq .total_count
```

Deja de ser cero ⇒ el reloj de GitHub sirve, el vigilante lo usa y el hueco se cierra sin trabajo.

## Acceptance Criteria

- [ ] Decidido cuál de las tres, y escrito por qué.
- [ ] Si es la 1, el `launchd` existe y se ha verificado que su corrida aparece en Actions.
