import { OffthreadVideo, staticFile, useCurrentFrame, useVideoConfig } from "remotion";
import type { Piece } from "../brand/copy";
import { FONT_STACK } from "../brand/font";
import { yala } from "../brand/tokens";
import { cameraAt, cameraRect } from "../lib/layout";

/**
 * El trozo de VERDAD DEL PRODUCTO: la grabación real del iPhone, con cámara.
 *
 * Reglas duras:
 *  1. `OffthreadVideo`, no `<Video>`. Muestrea el frame exacto al renderizar,
 *     y aquí el origen va a 60 fps contra una composition de 30.
 *  2. El footage NO se recolorea, NO se estira y NO se reconstruye. Si la UI
 *     de la toma está mal, se vuelve a grabar; no se retoca aquí.
 *  3. La cámara RECORTA, nunca deforma: el ancho manda y el alto sale de la
 *     proporción del origen. Mover la cámara no cambia lo que la app hizo.
 *
 * Va **a sangre**, sin marco de teléfono. Un mockup de iPhone flotando en medio
 * de un fondo negro deja el 40 % del lienzo vacío, y en un feed ese 40 % es
 * espacio que no cuenta nada.
 */
export const DeviceFrame: React.FC<{
  piece: Piece;
  /** Recorta a una caja en vez de ir a sangre (lo usa el lienzo 16:9). */
  box?: { left: number; top: number; width: number; height: number; radius: number };
}> = ({ piece, box }) => {
  const frame = useCurrentFrame();
  const { width: canvasW, height: canvasH } = useVideoConfig();

  const viewW = box?.width ?? canvasW;
  const viewH = box?.height ?? canvasH;

  const { focusY, scale } = cameraAt(piece.shots, frame);
  const rect = cameraRect({
    canvasW: viewW,
    canvasH: viewH,
    source: piece.source,
    crop: piece.crop,
    focusY,
    scale,
  });

  return (
    <div
      style={{
        position: "absolute",
        left: box?.left ?? 0,
        top: box?.top ?? 0,
        width: viewW,
        height: viewH,
        overflow: "hidden",
        borderRadius: box?.radius ?? 0,
        background: yala.color.bg,
        // El marco solo existe cuando hay caja. A sangre no se dibuja nada.
        border: box ? `2px solid rgba(255,255,255,0.16)` : undefined,
        boxShadow: box
          ? `0 40px 120px rgba(0,0,0,0.7), 0 0 160px ${yala.color.indigo}33`
          : undefined,
      }}
    >
      {piece.footage ? (
        <div
          style={{
            position: "absolute",
            left: rect.left,
            top: rect.top,
            width: rect.width,
            height: rect.height,
            overflow: "hidden",
          }}
        >
          {/* El recorte se hace estirando el vídeo COMPLETO y tapando con
              overflow; así `crop` quita píxeles sin tocar la proporción. */}
          <OffthreadVideo
            src={staticFile(piece.footage)}
            style={{
              position: "absolute",
              left: 0,
              top: -cropPx(piece, rect.width),
              width: rect.width,
              height: fullHeight(piece, rect.width),
              objectFit: "fill",
            }}
          />
        </div>
      ) : (
        <MissingFootage slug={piece.slug} />
      )}
    </div>
  );
};

const fullHeight = (piece: Piece, width: number) =>
  (width * piece.source.h) / piece.source.w;

const cropPx = (piece: Piece, width: number) =>
  fullHeight(piece, width) * (piece.crop?.top ?? 0);

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
    <div style={{ fontSize: 46, fontWeight: 800, color: yala.color.white }}>
      Falta la toma
    </div>
    <div style={{ fontSize: 30, color: yala.color.textSecondary }}>{slug}</div>
    <div style={{ fontSize: 24, color: yala.color.textSecondary, maxWidth: 520 }}>
      Graba la pantalla del iPhone, copia el mp4 a <code>public/footage/</code> y
      apúntalo en <code>src/brand/copy.ts</code>.
    </div>
  </div>
);
