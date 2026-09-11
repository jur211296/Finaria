import { OffthreadVideo, staticFile } from "remotion";
import type { Piece } from "../brand/copy";
import { FONT_STACK } from "../brand/font";
import { frameTheme, glass, yala } from "../brand/tokens";
import { visibleFraction } from "../lib/layout";

/**
 * El trozo de VERDAD DEL PRODUCTO: la grabación real del iPhone, encajada.
 *
 * Reglas duras, las tres:
 *  1. `OffthreadVideo`, no `<Video>`. Es lo que muestrea el frame exacto al
 *     renderizar, y aquí el origen va a 60 fps contra una composition de 30.
 *  2. El footage NO se recolorea, NO se estira y NO se reconstruye. Si la UI
 *     de la toma está mal, se vuelve a grabar; no se retoca aquí.
 *  3. `crop` recorta, nunca escala de más: el ancho manda y el alto sale de la
 *     proporción del origen por la fracción visible.
 */
export const DeviceFrame: React.FC<{
  piece: Piece;
  left: number;
  top: number;
  width: number;
  height: number;
  radius?: number;
}> = ({ piece, left, top, width, height, radius = 44 }) => {
  const theme = frameTheme(piece.theme);

  // Alto que tendría el origen COMPLETO a este ancho; el recorte se aplica
  // desplazando el vídeo hacia arriba dentro de un contenedor con overflow.
  const fullHeight = (width * piece.source.h) / piece.source.w;
  const offsetTop = -fullHeight * (piece.crop?.top ?? 0);

  return (
    <div
      style={{
        position: "absolute",
        left,
        top,
        width,
        height,
        borderRadius: radius,
        overflow: "hidden",
        border: `1px solid ${glass.strokeStrong}`,
        boxShadow: `${glass.shadow}, 0 0 120px ${yala.color.indigo}22`,
        background: theme.bg,
      }}
    >
      {piece.footage ? (
        <OffthreadVideo
          src={staticFile(piece.footage)}
          style={{
            position: "absolute",
            left: 0,
            top: offsetTop,
            width,
            height: fullHeight,
            objectFit: "fill",
          }}
        />
      ) : (
        <MissingFootage slug={piece.slug} />
      )}
    </div>
  );
};

/**
 * Un slug del pack sin toma todavía. Enseña el hueco en vez de reventar el
 * Studio: la lista de piezas pendientes se ve de un vistazo.
 */
const MissingFootage: React.FC<{ slug: string }> = ({ slug }) => (
  <div
    style={{
      position: "absolute",
      inset: 0,
      display: "flex",
      flexDirection: "column",
      alignItems: "center",
      justifyContent: "center",
      gap: 18,
      background: `linear-gradient(160deg, ${yala.color.indigo}22, ${yala.color.bg})`,
      fontFamily: FONT_STACK,
      textAlign: "center",
      padding: 48,
    }}
  >
    <div style={{ fontSize: 34, fontWeight: 700, color: yala.color.white }}>
      Falta la toma
    </div>
    <div style={{ fontSize: 24, color: yala.color.textSecondary }}>{slug}</div>
    <div style={{ fontSize: 20, color: yala.color.textSecondary, maxWidth: 420 }}>
      Graba la pantalla del iPhone, copia el mp4 a <code>public/footage/</code> y
      apúntalo en <code>src/brand/copy.ts</code>.
    </div>
  </div>
);

/** Comprobación barata: que la caja pedida case con la proporción del origen. */
export const assertAspect = (piece: Piece, width: number, height: number) => {
  const expected = (width * piece.source.h * visibleFraction(piece.crop)) / piece.source.w;
  return Math.abs(expected - height) < 2;
};
