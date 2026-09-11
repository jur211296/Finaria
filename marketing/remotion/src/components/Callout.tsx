import { useCurrentFrame, useVideoConfig } from "remotion";
import type { CalloutSpec } from "../brand/copy";
import { FONT_STACK } from "../brand/font";
import { glass, yala } from "../brand/tokens";
import { titleMotion } from "../lib/timing";

/**
 * Píldora de cristal que nombra lo que el producto ACABA de enseñar.
 *
 * Nunca se adelanta al resultado: si el callout dice «ya está» antes de que la
 * pantalla lo muestre, la pieza está prometiendo en vez de demostrar.
 *
 * `tone: "gasto"` pinta el acento en rosa #FF0080 — la misma rima visual que el
 * monto en la app.
 */
export const Callout: React.FC<{
  text: string;
  tone?: CalloutSpec["tone"];
  sizePx?: number;
}> = ({ text, tone = "neutral", sizePx = yala.type.calloutPx }) => {
  const frame = useCurrentFrame();
  const { fps, durationInFrames } = useVideoConfig();
  const { opacity, translateY } = titleMotion({
    frame,
    fps,
    durationInFrames,
    travelPx: 18,
  });

  const accent = tone === "gasto" ? yala.color.pink : yala.color.teal;

  return (
    <div
      style={{
        display: "flex",
        justifyContent: "center",
        opacity,
        transform: `translateY(${translateY}px)`,
      }}
    >
      <div
        style={{
          display: "flex",
          alignItems: "center",
          gap: 16,
          padding: "18px 30px",
          borderRadius: 999,
          background: glass.panelStrong,
          border: `1px solid ${accent}66`,
          boxShadow: `${glass.shadow}, 0 0 40px ${accent}33`,
          backdropFilter: "blur(20px) saturate(140%)",
          WebkitBackdropFilter: "blur(20px) saturate(140%)",
        }}
      >
        <span
          style={{
            width: 12,
            height: 12,
            borderRadius: 999,
            background: accent,
            boxShadow: `0 0 16px ${accent}`,
            flexShrink: 0,
          }}
        />
        <span
          style={{
            fontFamily: FONT_STACK,
            fontWeight: 600,
            fontSize: sizePx,
            letterSpacing: "-0.01em",
            color: yala.color.white,
            whiteSpace: "nowrap",
          }}
        >
          {text}
        </span>
      </div>
    </div>
  );
};
