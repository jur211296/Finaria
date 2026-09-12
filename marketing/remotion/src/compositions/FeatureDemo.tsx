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
import { pieceBySlug, type Beat, type Locale, type Piece } from "../brand/copy";
import { FONT_STACK } from "../brand/font";
import { yala } from "../brand/tokens";
import { cue, sec } from "../lib/timing";
import { REELS_SAFE, REELS_STAGE, REELS_TEXT, WIDE_COPY, WIDE_DEVICE } from "../lib/layout";
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
 * Capa A (verdad del producto) = `DeviceFrame` con el footage real, intacto,
 * a sangre y con cámara: la vista va donde está el gesto.
 * Capa B (motion) = el hilo de beats encima.
 *
 * Las dos capas no se mezclan nunca: la app no se redibuja, se filma.
 */
export const FeatureDemo: React.FC<FeatureDemoProps> = ({
  slug,
  locale,
  aspect,
  showSafeAreas,
}) => {
  const piece = pieceBySlug(slug);

  const bodyFrames = sec(piece.footageSec);
  const endFrames = sec(piece.endCard?.durationSec ?? 0);
  const fade = yala.motion.fadeFrames;

  return (
    <AbsoluteFill style={{ background: yala.color.bg, fontFamily: FONT_STACK }}>
      <Sequence durationInFrames={bodyFrames} name="Cuerpo">
        {aspect === "9x16" ? (
          <Reels piece={piece} locale={locale} />
        ) : (
          <Wide piece={piece} locale={locale} />
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

type SideProps = { piece: Piece; locale: Locale };

/**
 * 9:16 — el lienzo de Reels. Footage a sangre, texto dentro de las safe areas.
 *
 * El footage puede pasar por debajo de la UI de Instagram; el TEXTO no, y los
 * gestos clave tampoco — de eso se ocupa la cámara en `copy.ts`.
 */
const Reels: React.FC<SideProps> = ({ piece, locale }) => (
  <AbsoluteFill>
    <Backdrop />
    <DeviceFrame piece={piece} box={REELS_STAGE} />

    {piece.beats.map((beat, i) => (
      <Sequence
        key={`${beat.fromSec}-${i}`}
        {...cue(beat.fromSec, beat.toSec)}
        name={`${i + 1}· ${beat.text.es}`}
      >
        <div
          style={{
            position: "absolute",
            left: REELS_SAFE.side,
            right: REELS_SAFE.side,
            ...(beat.place === "top"
              ? { top: REELS_TEXT.top }
              : { bottom: REELS_TEXT.bottom }),
            display: "flex",
            justifyContent: "center",
          }}
        >
          <BeatText beat={beat} locale={locale} />
        </div>
      </Sequence>
    ))}

    <Progress />
  </AbsoluteFill>
);

/**
 * Barra de avance bajo el teléfono.
 *
 * Ocupa la banda que Reels tapa con el caption, así que en Instagram casi no
 * se ve — y ese es el punto: en TikTok y Shorts sí, y ahí retiene, porque
 * enseña cuánto queda. Si desaparece bajo un caption no se pierde nada.
 */
const Progress: React.FC = () => {
  const frame = useCurrentFrame();
  const { durationInFrames } = useVideoConfig();
  const pct = interpolate(frame, [0, durationInFrames], [0, 1], {
    extrapolateRight: "clamp",
  });

  return (
    <div
      style={{
        position: "absolute",
        left: REELS_SAFE.side + 40,
        right: REELS_SAFE.side + 40,
        top: REELS_STAGE.top + REELS_STAGE.height + 60,
        height: 8,
        borderRadius: 999,
        background: "rgba(255,255,255,0.12)",
        overflow: "hidden",
      }}
    >
      <div
        style={{
          width: `${pct * 100}%`,
          height: "100%",
          borderRadius: 999,
          background: `linear-gradient(90deg, ${yala.color.indigo}, ${yala.color.pink})`,
          boxShadow: `0 0 24px ${yala.color.indigo}`,
        }}
      />
    </div>
  );
};

/**
 * El fondo. Glow índigo arriba —donde se sienta el texto— y teal abajo, para
 * que el negro no sea un negro plano de plantilla vacía.
 */
const Backdrop: React.FC = () => (
  <AbsoluteFill
    style={{
      background: `radial-gradient(78% 30% at 50% 14%, ${yala.color.indigo}3D, transparent 70%), radial-gradient(70% 26% at 50% 92%, ${yala.color.teal}22, transparent 70%)`,
    }}
  />
);

/** 16:9 — teléfono a la izquierda, columna de texto a la derecha. */
const Wide: React.FC<SideProps> = ({ piece, locale }) => {
  const deviceWidth = Math.round(
    (WIDE_DEVICE.height * piece.source.w) /
      (piece.source.h * (1 - (piece.crop?.top ?? 0) - (piece.crop?.bottom ?? 0))),
  );

  return (
    <AbsoluteFill>
      <AbsoluteFill
        style={{
          background: `radial-gradient(46% 70% at 22% 50%, ${yala.color.indigo}33, transparent 72%)`,
        }}
      />
      <DeviceFrame
        piece={piece}
        box={{
          left: WIDE_DEVICE.left,
          top: WIDE_DEVICE.top,
          width: deviceWidth,
          height: WIDE_DEVICE.height,
          radius: 48,
        }}
      />

      {piece.beats.map((beat, i) => (
        <Sequence
          key={`${beat.fromSec}-${i}`}
          {...cue(beat.fromSec, beat.toSec)}
          name={`${i + 1}· ${beat.text.es}`}
        >
          <div
            style={{
              position: "absolute",
              left: WIDE_COPY.left,
              right: WIDE_COPY.right,
              ...(beat.place === "top" ? { top: 190 } : { bottom: 190 }),
              display: "flex",
              justifyContent: "flex-start",
            }}
          >
            <BeatText beat={beat} locale={locale} typeScale={0.9} align="left" />
          </div>
        </Sequence>
      ))}
    </AbsoluteFill>
  );
};

const BeatText: React.FC<{
  beat: Beat;
  locale: Locale;
  typeScale?: number;
  align?: "center" | "left";
}> = ({ beat, locale, typeScale = 1, align = "center" }) =>
  beat.style === "pill" ? (
    <Callout text={beat.text[locale]} tone={beat.tone} typeScale={typeScale} />
  ) : (
    <AppleTitle
      text={beat.text[locale]}
      style={beat.style}
      place={beat.place}
      tone={beat.tone}
      typeScale={typeScale}
      align={align}
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
