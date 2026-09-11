import {
  AbsoluteFill,
  interpolate,
  Sequence,
  useCurrentFrame,
  useVideoConfig,
} from "remotion";
import { AppleTitle } from "../components/AppleTitle";
import { Callout } from "../components/Callout";
import { DeviceFrame } from "../components/DeviceFrame";
import { SafeAreas } from "../components/SafeAreas";
import { pieceBySlug, type Locale } from "../brand/copy";
import { FONT_STACK } from "../brand/font";
import { glass, yala } from "../brand/tokens";
import {
  CAPTION_BAND,
  deviceBox,
  REELS_DEVICE,
  REELS_SAFE,
  WIDE_COPY,
  WIDE_DEVICE,
} from "../lib/layout";
import { cue, sec } from "../lib/timing";
import { EndCard } from "./EndCard";

export type Aspect = "9x16" | "16x9";

export type FeatureDemoProps = {
  /** Clave de la pieza en `src/brand/copy.ts`. Es el único dato que se pasa a mano. */
  slug: string;
  locale: Locale;
  aspect: Aspect;
  /** Guías de Reels. Se encienden en Studio; en render van apagadas. */
  showSafeAreas: boolean;
};

/**
 * La plantilla. UNA sola para todas las piezas y los dos lienzos.
 *
 * Capa A (verdad del producto) = `DeviceFrame` con el footage real, intacto.
 * Capa B (motion estilo Apple) = título, callouts y end card, encima.
 * Las dos capas no se mezclan nunca: la app no se redibuja, se filma.
 */
export const FeatureDemo: React.FC<FeatureDemoProps> = ({
  slug,
  locale,
  aspect,
  showSafeAreas,
}) => {
  const piece = pieceBySlug(slug);
  const { width, height } = useVideoConfig();

  const bodyFrames = sec(piece.footageSec);
  const endFrames = sec(piece.endCard?.durationSec ?? 0);
  const fade = yala.motion.fadeFrames;

  return (
    <AbsoluteFill style={{ background: yala.color.bg, fontFamily: FONT_STACK }}>
      <Backdrop aspect={aspect} />

      <Sequence durationInFrames={bodyFrames} name="Cuerpo">
        {aspect === "9x16" ? (
          <Reels piece={piece} locale={locale} />
        ) : (
          <Wide piece={piece} locale={locale} width={width} height={height} />
        )}
      </Sequence>

      {piece.endCard ? (
        <Sequence
          from={Math.max(0, bodyFrames - fade)}
          durationInFrames={endFrames + fade}
          name="End card"
        >
          <FadeIn frames={fade}>
            <EndCard line={piece.endCard.line[locale]} wide={aspect === "16x9"} />
          </FadeIn>
        </Sequence>
      ) : null}

      {aspect === "9x16" ? <SafeAreas visible={showSafeAreas} /> : null}
    </AbsoluteFill>
  );
};

// --------------------------------------------------------------------------

type SideProps = {
  piece: ReturnType<typeof pieceBySlug>;
  locale: Locale;
};

/** 9:16 — el lienzo de Reels. Geometría medida, ver docs/SHOT-CONTRACT.md. */
const Reels: React.FC<SideProps> = ({ piece, locale }) => {
  const { width } = useVideoConfig();
  const box = deviceBox({ width: REELS_DEVICE.width, source: piece.source, crop: piece.crop });
  const left = Math.round((width - box.width) / 2);
  const top = REELS_DEVICE.top;

  // Banda libre del footage: debajo de los chips y encima de la barra de
  // escritura. Es donde caben hook y callout sin tapar lo que importa.
  const bandTop = Math.round(top + box.height * CAPTION_BAND.topFraction);
  const bandBottom = Math.round(top + box.height * CAPTION_BAND.bottomFraction);

  // El callout va 140 px por debajo del hook —los dos nunca coinciden en el
  // tiempo— y con tope duro: medido sobre el render, sin el clamp la píldora
  // acababa encima de la barra de escritura de la app.
  const calloutTop = Math.min(bandTop + 140, bandBottom - 80);

  // La columna de texto sigue al teléfono en vez de irse a las safe areas.
  // Un panel más ancho que el device se lee como pegatina, no como rótulo.
  const columnLeft = Math.max(REELS_SAFE.side, left - 40);
  const columnWidth = width - columnLeft * 2;

  return (
    <AbsoluteFill>
      <DeviceFrame piece={piece} left={left} top={top} {...box} />

      {piece.hook ? (
        <Sequence {...cue(piece.hook.fromSec, piece.hook.toSec)} name="Hook">
          <div style={{ position: "absolute", left: columnLeft, width: columnWidth, top: bandTop }}>
            <AppleTitle text={piece.hook.text[locale]} maxWidth={columnWidth} />
          </div>
        </Sequence>
      ) : null}

      {piece.callouts.map((c, i) => (
        <Sequence key={c.fromSec} {...cue(c.fromSec, c.toSec)} name={`Callout ${i + 1}`}>
          <div style={{ position: "absolute", left: 0, right: 0, top: calloutTop }}>
            <Callout text={c.text[locale]} tone={c.tone} />
          </div>
        </Sequence>
      ))}
    </AbsoluteFill>
  );
};

/** 16:9 — teléfono a la izquierda sobre placa de cristal, texto a la derecha. */
const Wide: React.FC<SideProps & { width: number; height: number }> = ({
  piece,
  locale,
  width,
}) => {
  const deviceWidth = Math.round(
    (WIDE_DEVICE.height * piece.source.w) /
      (piece.source.h * (1 - (piece.crop?.top ?? 0) - (piece.crop?.bottom ?? 0))),
  );
  const box = deviceBox({ width: deviceWidth, source: piece.source, crop: piece.crop });
  const copyWidth = width - WIDE_COPY.left - WIDE_COPY.right;

  return (
    <AbsoluteFill>
      {/* Margen glass: la placa que sostiene el teléfono y separa del fondo. */}
      <div
        style={{
          position: "absolute",
          left: WIDE_DEVICE.left - 56,
          top: WIDE_DEVICE.top - 36,
          width: box.width + 112,
          height: box.height + 72,
          borderRadius: 72,
          background: glass.panel,
          border: `1px solid ${glass.stroke}`,
          backdropFilter: "blur(30px)",
          WebkitBackdropFilter: "blur(30px)",
        }}
      />
      <DeviceFrame piece={piece} left={WIDE_DEVICE.left} top={WIDE_DEVICE.top} {...box} />

      {piece.hook ? (
        <Sequence {...cue(piece.hook.fromSec, piece.hook.toSec)} name="Hook">
          <div style={{ position: "absolute", left: WIDE_COPY.left, top: 340, width: copyWidth }}>
            <AppleTitle
              text={piece.hook.text[locale]}
              sizePx={yala.type.heroPx169}
              align="left"
              maxWidth={copyWidth}
            />
          </div>
        </Sequence>
      ) : null}

      {piece.callouts.map((c, i) => (
        <Sequence key={c.fromSec} {...cue(c.fromSec, c.toSec)} name={`Callout ${i + 1}`}>
          <div
            style={{
              position: "absolute",
              left: WIDE_COPY.left,
              top: 470,
              width: copyWidth,
              display: "flex",
              justifyContent: "flex-start",
            }}
          >
            <Callout text={c.text[locale]} tone={c.tone} />
          </div>
        </Sequence>
      ))}
    </AbsoluteFill>
  );
};

/** Glow de fondo. Es lo único del marco que no es negro plano. */
const Backdrop: React.FC<{ aspect: Aspect }> = ({ aspect }) => (
  <AbsoluteFill
    style={{
      background:
        aspect === "9x16"
          ? `radial-gradient(70% 34% at 50% 12%, ${yala.color.indigo}2E, transparent 72%), radial-gradient(60% 30% at 50% 96%, ${yala.color.teal}18, transparent 70%)`
          : `radial-gradient(46% 70% at 22% 50%, ${yala.color.indigo}2E, transparent 72%)`,
    }}
  />
);

const FadeIn: React.FC<{ frames: number; children: React.ReactNode }> = ({
  frames,
  children,
}) => {
  const frame = useCurrentFrame();
  const opacity = interpolate(frame, [0, frames], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });
  return <AbsoluteFill style={{ opacity }}>{children}</AbsoluteFill>;
};
