import { yala } from "../brand/tokens";

/**
 * Geometría del marco. Los números NO son gusto: salen de medir el footage real
 * del piloto con ffmpeg (ver docs/SHOT-CONTRACT.md, tabla «dónde cae cada cosa»).
 *
 * Va aparte de tokens.ts a propósito: tokens.ts es la MARCA (lo que no cambia
 * entre piezas) y esto es el ENCUADRE (lo que se recalcula si cambia el lienzo).
 */

/**
 * Zonas que Instagram tapa con su propia UI en Reels, medidas sobre 1080×1920.
 * No se recortan: se respetan. `SafeAreas` las dibuja en Studio para comprobarlo.
 */
export const REELS_SAFE = { top: 220, bottom: 400, side: 64 } as const;

export type Crop = { top?: number; bottom?: number };

/** Alto visible del origen una vez aplicado el recorte, en fracción (0–1). */
export const visibleFraction = (crop?: Crop) =>
  1 - (crop?.top ?? 0) - (crop?.bottom ?? 0);

/**
 * Encaje del device a partir del ancho deseado: devuelve el alto que le toca
 * al trozo VISIBLE del origen, no al origen entero.
 */
export const deviceBox = ({
  width,
  source,
  crop,
}: {
  width: number;
  source: { w: number; h: number };
  crop?: Crop;
}) => {
  const height = Math.round((width * source.h * visibleFraction(crop)) / source.w);
  return { width, height };
};

/**
 * Encuadre 9:16 del piloto. Device 700 px de ancho, arriba a 170 px.
 *
 * Con esto la barra de escritura del chat cae en y≈1337–1442 del lienzo, o sea
 * POR ENCIMA de los 1520 px donde Reels tapa con el caption. A sangre completa
 * el tipeo —que es medio relato— quedaría debajo de la UI de Instagram.
 */
export const REELS_DEVICE = { width: 700, top: 170 } as const;

/** Encuadre 16:9: el teléfono a la izquierda, la columna de texto a la derecha. */
export const WIDE_DEVICE = { height: 936, top: 72, left: 230 } as const;
export const WIDE_COPY = { left: 800, right: 140 } as const;

/** Banda libre del footage donde entran hook y callout sin tapar nada. */
export const CAPTION_BAND = { topFraction: 0.58, bottomFraction: 0.86 } as const;

export const canvasOf = (aspect: "9x16" | "16x9") =>
  aspect === "9x16" ? yala.canvas.reels : yala.canvas.youtube;
