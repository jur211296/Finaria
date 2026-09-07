---
id: gateway-typecheck-roto-y-fuera-del-ci
status: backlog
priority: low
area: "gateway, ci, tooling"
created: 2026-09-07
updated: 2026-09-07
source: hallazgo lateral de groups-budget (2026-09-07)
---

# El `typecheck` del gateway falla, y nadie se entera porque el CI no lo corre

## Qué pasa

`npm run typecheck` en `gateway/` termina con **3 errores de TypeScript**. Medido el 2026-09-07 en
el worktree de `groups-budget`, sobre ficheros que esa sesión **no tocó** (`git status` los daba
idénticos a HEAD), así que no son suyos:

```
test/groups.consent.test.ts(129,48): error TS2345: Argument of type '{ "Content-Type": string; }'
  is not assignable to parameter of type '{ Authorization: string; "Content-Type": string; }'.
  Property 'Authorization' is missing …
test/wrangler.forceupdate.test.ts(26,30): error TS2307: Cannot find module 'node:fs' …
test/wrangler.forceupdate.test.ts(29,67): error TS2339: Property 'url' does not exist on type 'ImportMeta'.
```

## Por qué no salta nadie

Dos causas, y las dos son del repo, no del entorno de quien lo corrió:

1. **`@types/node` no está declarado.** `gateway/package.json` lista cuatro devDependencies
   (`@cloudflare/workers-types`, `typescript`, `vitest`, `wrangler`) y ninguna trae los tipos de
   Node, así que `node:fs` e `import.meta.url` no resuelven en NINGUNA máquina — no es un
   `npm install` a medias de nadie.
2. **El CI no ejecuta `typecheck`.** `grep -n "typecheck" .github/workflows/*.yml` da cero
   resultados. El comando existe, está bien cableado como `pretypecheck` → `sync:manifest`, y no lo
   invoca ningún job.

⇒ el error puede llevar semanas ahí. `npm test` sí pasa (253 tests), así que nada lo delata.

## Por qué importa poco hoy y puede importar mañana

Hoy no rompe nada: los tres errores están en ficheros de TEST y `vitest` transpila sin comprobar
tipos, así que la suite corre igual y el Worker despliega igual (`deploy` no depende de
`typecheck`). Lo que se pierde es la red: un error de tipos en `src/` —donde sí vive el código que
se despliega— tampoco lo vería nadie, porque el comando que lo cazaría ya está en rojo y su rojo se
ha vuelto ruido de fondo.

## Qué habría que hacer

1. Añadir `@types/node` a devDependencies (y `"types": ["node"]` en el `tsconfig` si hace falta).
2. Arreglar el header de `groups.consent.test.ts:129` (le falta `Authorization`).
3. Meter `npm run typecheck` en el job del gateway del CI, **como bloqueante**: un typecheck que no
   bloquea es un typecheck que vuelve a ponerse rojo.

## Cómo se reproduce

```
cd gateway && npm install && npm run typecheck
```

## Nota de proceso

Sale de la sesión de `groups-budget`, que lo encontró al validar su propio cambio del manifest. Se
comprobó que **no era suyo** antes de abrir el ticket: los dos ficheros con error estaban sin
modificar respecto a HEAD, y la causa (`@types/node` ausente en `package.json`) es estructural del
repo, no del entorno de esa sesión.
