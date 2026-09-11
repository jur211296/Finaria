# Operación diaria — estudio de demos de Yala

Cómo sale un Reel desde que grabas la pantalla del iPhone hasta que hay un mp4.
Diez minutos si la toma está bien; si la toma está mal, se vuelve a grabar — **el
footage no se retoca aquí.**

---

## El bucle

### 1 · Graba la pantalla del iPhone

La app de verdad, con datos de ejemplo. **Nunca con datos reales de nadie.**

Checklist de toma, y cada punto está aquí porque ya falló una vez:

- [ ] **Tema Liquid Glass oscuro.** Light / Rosa / Teal / Minimalist son temas de la app,
      no el look del pack 2.1.
- [ ] **Status bar limpia.** Sin la píldora roja de grabación. Se consigue grabando
      desde QuickTime con el iPhone conectado, no con la grabadora del propio iPhone.
- [ ] **Datos de ejemplo.** Ojo con los chips de sugerencia de Yala IA: se generan
      con las categorías reales del usuario y **se leen en el vídeo**.
- [ ] **Un solo gesto por plano.** Si dudas dos segundos antes de tocar, se nota.
- [ ] **Sin notificaciones.** Modo avión o No molestar.

### 2 · Copia el fichero

```bash
cp ~/ruta/a/la/toma.mp4 marketing/remotion/public/footage/<slug>.mp4
ffprobe -v error -show_entries stream=width,height -show_entries format=duration \
  -of default=noprint_wrappers=1 marketing/remotion/public/footage/<slug>.mp4
```

Apunta la duración y la resolución: van literales a `copy.ts`. **No se estiman.**

### 3 · Escribe el guion en `src/brand/copy.ts`

Ni una palabra de copy vive en el JSX. Una entrada nueva en `PIECES`:

```ts
{
  slug: "voz-gasto-hablado",
  title: "Registra hablando",
  footage: "footage/voz-gasto-hablado.mp4",
  footageSec: 12.4,                    // lo que dijo ffprobe
  source: { w: 1170, h: 2532 },        // lo que dijo ffprobe
  crop: { top: 0.05 },                 // solo si hay que tapar la status bar
  theme: "dark",
  hook: { fromSec: 0.2, toSec: 1.4, text: { es: "…", en: "…" } },
  callouts: [{ fromSec: 8.2, toSec: 10.4, tone: "gasto", text: { es: "…", en: "…" } }],
  endCard: END_CARD,
}
```

El copy sigue la voz de `marketing/screenshots-appstore/captions.md`: **cercana, sin
regañar**. La gente no deja de llevar sus cuentas por falta de disciplina, sino por
fricción. Si una línea suena a reproche, está mal aunque convierta.

### 4 · Míralo en Studio

```bash
cd marketing/remotion && bun run studio
```

Abre `FeatureDemo-9x16`. En el panel de props, `showSafeAreas: true` dibuja en rosa
las bandas que Instagram tapa con su UI. **Si algo importante cae dentro, se mueve el
encuadre, no se publica y ya.**

### 5 · Renderiza

```bash
bun run render:reels                    # piloto, es, 9:16
bash scripts/render-reels.sh <slug> es  # una pieza, 9:16
bash scripts/render-reels.sh <slug> en --aspect 16x9
bun run render:pack                     # todas las piezas CON toma, los dos lienzos
```

Sale a `out/<slug>-<locale>-<aspect>.mp4`, que **no se commitea**.

### 6 · Comprueba antes de publicar

Los scripts ya comprueban que el fichero existe, que pesa algo y cuánto dura — pero eso
solo dice que hay vídeo, no que el vídeo esté bien. Antes de que salga:

- [ ] Míralo entero, con sonido apagado, en un teléfono.
- [ ] **Los siete idiomas de la ficha se tocan juntos o no se tocan** (esto vale para la
      App Store, no para un Reel, pero el reflejo es el mismo: nada a medias).
- [ ] Publicar es hacia fuera y no se deshace. **Espera el visto bueno de Jürgen.**

---

## Tres herramientas, tres trabajos distintos

Se confunden con facilidad y hacen cosas que no se parecen en nada.

| | Qué es | Cuándo | Qué NO es |
|---|---|---|---|
| **`FeatureDemo`** (esta plantilla) | El motor del pack 2.1: footage real + rótulos | **El default.** Toda demo de una función de Yala | No dibuja UI. Si no hay toma, no hay pieza |
| **`video-shotcraft` / `ai-product-video`** (skills) | Catálogo de planos: timing, energía, tipos de movimiento | Para **decidir** 2–4 planos antes de grabar, y anotarlos en `SHOT-CARDS.md` | **NO se usa su pipeline.** Reconstruye la app con capturas de página y trae la estética Ink Press. Ni una ni otra son Yala. Su template de 36 s **no se renderiza como demo de Yala** |
| **`anything2explainer`** (skill) | Explainer con voz en off, fondo negro, capítulos | Nada todavía | Slug **`explainer-que-es-yala-ia` reservado en `copy.ts`, sin composition y sin render**. Cuando toque, se decide primero la voz. **Sin ElevenLabs por ahora** |

De las dos skills de planos, **`video-shotcraft` y `ai-product-video` son el mismo
contenido con dos nombres** (misma descripción, mismo template). Están las dos instaladas
porque el encargo las pedía; usa una.

Y el color de cualquier plano que salga de ahí **se remapea a los tokens de Yala**
(`src/brand/tokens.ts`) antes de tocar una composition.

---

## Grok Imagine: solo atmósfera, y no corre aquí

Imagine sirve para **B-roll de ambiente** —dos segundos de una mesa, una mano, una calle—
y para nada más. **La UI de Yala jamás se genera con IA**: ni Imagine, ni Higgsfield, ni
Kling, ni Sora, ni Remotion dibujando un iPhone.

Imagine **no está en Claude Code**. Lo tira Jürgen o el bot de Lola en Grok. Desde aquí se
prepara el prompt y se dice; no se finge que se puede generar.

---

## Reinstalar las skills en una Mac nueva

No están vendorizadas en el repo a propósito: son dependencias externas que se actualizan
solas y meterlas al git de Yala son miles de ficheros de terceros sin revisar.

```bash
npx skills add remotion-dev/skills -g -a '*' -y
npx skills add Vincentwei1021/video-shotcraft -g -a claude-code -y
npx skills add dlazy-ai/ai-product-video -g -a claude-code -y
npx skills add Vincentwei1021/anything2explainer -g -a claude-code -y

# Espejo para Codex
mkdir -p ~/.codex/skills
for s in ~/.claude/skills/remotion-* ~/.claude/skills/video-shotcraft \
         ~/.claude/skills/ai-product-video ~/.claude/skills/anything2explainer; do
  ln -sfn "$s" ~/.codex/skills/"$(basename "$s")"
done

# Plugin oficial. `claude plugin install` clona por SSH y falla sin clave de GitHub;
# esto lo fuerza a HTTPS solo para ese comando, sin tocar la config global de git.
claude plugin marketplace add remotion-dev/claude-code-plugin
GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0="url.https://github.com/.insteadOf" \
  GIT_CONFIG_VALUE_0="git@github.com:" claude plugin install remotion@remotion
```

---

## Trampas medidas (2026-09-11)

**rspack deja el bundle sin JS, y el error no lo menciona.** El scaffold oficial trae
`Config.setRspack(true)`. Con Remotion 4.0.523 + bun 1.3.11 en macOS arm64 eso produce un
bundle **sin `bundle.js`** —solo `index.html`, `favicon.ico` y `public/`— y el render muere
con `ENOENT … bundle.js` desde `getSourceMapFromLocalFile`, que suena a problema de source
maps. Pasa con y sin el override de Tailwind. `remotion.config.ts` lo deja apagado con la
nota. Para comprobar si ya se arregló: `bunx remotionb bundle --out-dir=/tmp/x` y mirar si
existe `/tmp/x/bundle.js`.

**El footage va a 60 fps y la composition a 30.** `OffthreadVideo` remapea solo, pero es la
razón por la que `<Video>` no vale aquí: `OffthreadVideo` muestrea el frame exacto al
renderizar. No lo cambies.

**`scripts/*.sh` están escritos para bash 3.2**, que es el que trae macOS. Sin `mapfile` y
sin expandir arrays vacíos bajo `set -u`: las dos cosas revientan ahí.

---

## Deuda de la toma piloto

`ia-gasto-pizza-16s.mp4` entra al repo porque el sistema tenía que probarse con footage de
verdad, pero **tiene tres cosas que hay que arreglar antes de publicarla**:

1. **Tema Light.** El pack 2.1 es Liquid Glass oscuro. El marco de la pieza sí va oscuro,
   pero la pantalla no.
2. **Píldora roja de grabación** los 16 s. Parcheada con `crop: { top: 0.05 }`, que se lleva
   la status bar entera. Es un parche.
3. **Datos que parecen reales** — los chips citan «el presupuesto de Maia 🐕», y la lista
   final trae saldo PEN 8175.00, Uber, Supermercado y una fila «Compartido».
   **Esto no sale a ningún sitio sin un sí explícito de Jürgen, o con seed de demo.**
