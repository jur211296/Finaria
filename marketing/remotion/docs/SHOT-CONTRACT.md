# Shot contract — qué promete la plantilla y qué no

El contrato entre el guion (`src/brand/copy.ts`) y el motor
(`src/compositions/FeatureDemo.tsx`). Si algo de aquí cambia, cambia para todas las piezas.

---

## Las dos capas, que no se mezclan nunca

**Capa A · verdad del producto.** La grabación real del iPhone, sin recolorear, sin
estirar y sin reconstruir. Vive en `DeviceFrame` y llega por `OffthreadVideo`.
La UI de Yala **jamás** se genera con IA ni se redibuja en React.

**Capa B · motion estilo Apple.** Rótulos, callouts, end card, springs, fades.
Vive encima, nunca dentro.

Si la Capa A está mal, se vuelve a grabar. La Capa B no arregla una toma mala: la disfraza.

---

## Los props

Una sola cosa se pasa a mano: **el `slug`**. Todo lo demás sale de `copy.ts`.

```ts
type FeatureDemoProps = {
  slug: string;                 // clave en PIECES
  locale: "es" | "en";
  aspect: "9x16" | "16x9";
  showSafeAreas: boolean;       // guía de Studio; en render va false
};
```

Y la pieza que el `slug` resuelve:

| Campo | Qué es | Regla |
|---|---|---|
| `footage` | Ruta dentro de `public/`, o `null` | `null` pinta el cartel «falta la toma» en vez de reventar |
| `footageSec` | Duración **medida con ffprobe** | Nunca se estima. De aquí sale `durationInFrames` |
| `source` | `{ w, h }` del origen | Encaja sin deformar. Si mientes aquí, el vídeo se estira |
| `crop` | Fracción que se recorta arriba/abajo | Recorta, no escala. Para tapar una status bar sucia |
| `theme` | `dark` \| `light` | Es el **marco**. El footage no se recolorea nunca |
| `hook` | Máx. 6 palabras, ES + EN | Si no cabe en un respiro, no es un hook |
| `callouts[]` | Píldora con `fromSec`/`toSec` | **Entra cuando el producto YA enseñó el resultado.** Si se adelanta, la pieza promete en vez de demostrar |
| `endCard` | Wordmark + una línea | Una línea. No dos |

`durationInFrames` **no se escribe**: lo calcula `calculateMetadata` como
`footageSec + endCard.durationSec`. Cambiar el mp4 por uno más largo actualiza la línea de
tiempo sola.

---

## La geometría, y de dónde salen los números

No son gusto. Salen de medir el footage del piloto con `ffmpeg`, frame a frame:

| Momento del piloto | Dónde cae en la pantalla del iPhone |
|---|---|
| Chips de sugerencia (0–1,4 s) | 30 %–53 % del alto |
| Card de confirmación (5,8–8,0 s) | 27 %–73 % ← **el plano estrella, no se tapa** |
| Fila de éxito «Pizza · PEN 20.00 · Registrado» (11,3–13,9 s) | 32 %–40 % |
| Banda vacía en el momento de éxito | 52 %–80 % ← ahí va el callout |
| Barra de escritura (1,4–3,7 s) | 82 %–89 % |

De ahí sale el encuadre 9:16 de `src/lib/layout.ts`: **device de 700 px de ancho, arriba a
170 px**. Con eso la barra de escritura cae en y≈1337–1442 del lienzo, o sea **por encima de
los 1520 px donde Reels tapa con el caption**. A sangre completa el tipeo —que es medio
relato— quedaría debajo de la UI de Instagram.

`REELS_SAFE` (top 220, bottom 400, side 64) **no recorta nada**: `SafeAreas` lo dibuja en
punteado para comprobarlo en Studio, y va apagado en render.

El encuadre 9:16 admite que el **bisel** del device entre en la banda superior. Lo que no
admite es que entre un gesto, un monto o un rótulo.

`src/lib/layout.ts` va aparte de `tokens.ts` a propósito: **tokens es la marca** (lo que no
cambia entre piezas) y **layout es el encuadre** (lo que se recalcula si cambia el lienzo).

---

## Tipografía: Inter es un sustituto, y conviene saberlo

La referencia real de Yala es **SF Pro Rounded**, y no se puede empaquetar en un render web.
Se usa **Inter** (`@remotion/google-fonts/Inter`, cargada una sola vez en `src/brand/font.ts`).
No leas las piezas como «así se ve la tipografía de Yala»: se parece, no es.

---

## Divergencia de marca detectada, sin tocar

`Web/public/logo.svg` construye el wordmark con **cian neón `#00F3FF`**. Los tokens 2.1 dicen
**teal `#00C2CB`**. La `EndCard` usa el token 2.1, que es lo que manda para el pack.
**La web no se toca desde aquí** — queda anotado para que alguien lo decida, no para que se
arregle por la espalda.
