import { useCurrentFrame, useVideoConfig } from "remotion";
import { FONT_STACK } from "../brand/font";
import { glass, yala } from "../brand/tokens";
import { titleMotion } from "../lib/timing";

/**
 * Título estilo Apple: entra con spring, se sostiene, sale con fade.
 *
 * Va sobre un panel de cristal oscuro y no sobre el vídeo pelado: el footage
 * del piloto es tema Light, así que texto blanco a pelo no se leería. El panel
 * es lo que hace que la misma plantilla sirva para tomas claras y oscuras.
 */
export const AppleTitle: React.FC<{
  text: string;
  /** `heroPx` en 9:16, `heroPx169` en 16:9. */
  sizePx?: number;
  align?: "center" | "left";
  maxWidth?: number;
}> = ({ text, sizePx = yala.type.heroPx, align = "center", maxWidth = 860 }) => {
  const frame = useCurrentFrame();
  const { fps, durationInFrames } = useVideoConfig();
  const { opacity, translateY, scale } = titleMotion({ frame, fps, durationInFrames });

  return (
    <div
      style={{
        display: "flex",
        justifyContent: align === "center" ? "center" : "flex-start",
        opacity,
        transform: `translateY(${translateY}px) scale(${scale})`,
      }}
    >
      <div
        style={{
          maxWidth,
          padding: "26px 40px",
          borderRadius: 30,
          background: glass.panelStrong,
          border: `1px solid ${glass.stroke}`,
          boxShadow: glass.shadow,
          backdropFilter: "blur(24px) saturate(140%)",
          WebkitBackdropFilter: "blur(24px) saturate(140%)",
        }}
      >
        <div
          style={{
            fontFamily: FONT_STACK,
            fontWeight: 700,
            fontSize: sizePx,
            lineHeight: 1.06,
            letterSpacing: "-0.025em",
            color: yala.color.white,
            textAlign: align,
            textWrap: "balance",
          }}
        >
          {text}
        </div>
      </div>
    </div>
  );
};
