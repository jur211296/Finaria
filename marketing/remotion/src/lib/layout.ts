import { Easing, interpolate } from "remotion";
import type { Shot } from "../brand/copy";
import { yala } from "../brand/tokens";

/**
 * Encuadre y CÁMARA.
 *
 * Va aparte de tokens.ts a propósito: tokens es la MARCA (lo que no cambia
 * entre piezas) y esto es el ENCUADRE (lo que se recalcula con el lienzo).
 */

/**
 * Zonas que Instagram tapa con su propia UI en Reels, medidas sobre 1080×1920.
 * El footage va a sangre por debajo; lo que se respeta es que **ningún texto y
 * ningún gesto clave** caiga dentro.
 */
export const REELS_SAFE = { top: 220, bottom: 400, side: 64 } as const;

export type Crop = { top?: number; bottom?: number };

/** Alto visible del origen una vez aplicado el recorte, en fracción (0–1). */
export const visibleFraction = (crop?: Crop) =>
  1 - (crop?.top ?? 0) - (crop?.bottom ?? 0);

const clamp = (v: number, min: number, max: number) =>
  Math.min(Math.max(v, min), max);

/**
 * Dónde va el vídeo en el lienzo para un plano dado.
 *
 * `scale` 1 llena el ancho. Como el iPhone (19,5:9) es más alto que el lienzo
 * (16:9), SIEMPRE sobra alto: ese sobrante es lo que permite mover la cámara
 * en vertical sin dejar hueco. El clamp garantiza que no se vea el fondo.
 */
export const cameraRect = ({
  canvasW,
  canvasH,
  source,
  crop,
  focusY,
  scale,
}: {
  canvasW: number;
  canvasH: number;
  source: { w: number; h: number };
  crop?: Crop;
  focusY: number;
  scale: number;
}) => {
  const width = canvasW * scale;
  const height = (width * source.h * visibleFraction(crop)) / source.w;
  const left = (canvasW - width) / 2;

  const top =
    height <= canvasH
      ? (canvasH - height) / 2
      : clamp(canvasH / 2 - focusY * height, canvasH - height, 0);

  return { left, top, width, height };
};

/**
 * Cuánto tarda la cámara en viajar de un plano al siguiente, en segundos.
 * Lo que sobra del tramo, el plano se SOSTIENE.
 */
export const CAMERA_MOVE_SEC = 0.65;

/**
 * Interpola la lista de planos en el frame actual.
 *
 * Dos cosas, y la primera costó una versión entera:
 *
 * 1. **La cámara se sostiene y luego viaja.** Interpolar de un `atSec` al
 *    siguiente sin parar suena razonable y es justo lo que rompe la pieza:
 *    la cámara está SIEMPRE en tránsito, así que ningún encuadre llega a
 *    leerse. Medido — a 0,9 s la vista ya iba por la mitad del camino al plano
 *    de 1,7 s y de los tres chips solo se veía uno. Aquí cada plano se queda
 *    quieto y el viaje ocupa solo los últimos `CAMERA_MOVE_SEC`.
 * 2. **`inOut(cubic)`**, no lineal: una cámara que arranca y para en seco se
 *    lee como un salto de vídeo roto, no como un movimiento.
 */
export const cameraAt = (shots: Shot[], frame: number) => {
  if (shots.length === 0) return { focusY: 0.5, scale: 1 };
  if (shots.length === 1) return { focusY: shots[0].focusY, scale: shots[0].scale };

  const fps = yala.motion.fps;
  const move = Math.round(CAMERA_MOVE_SEC * fps);

  const times: number[] = [];
  const focus: number[] = [];
  const scale: number[] = [];

  shots.forEach((shot, i) => {
    const at = Math.round(shot.atSec * fps);
    if (i === 0) {
      times.push(at);
      focus.push(shot.focusY);
      scale.push(shot.scale);
      return;
    }
    // El plano anterior se sostiene hasta `move` frames antes de este.
    const holdUntil = Math.max(at - move, times[times.length - 1] + 1);
    times.push(holdUntil);
    focus.push(shots[i - 1].focusY);
    scale.push(shots[i - 1].scale);

    times.push(Math.max(at, holdUntil + 1));
    focus.push(shot.focusY);
    scale.push(shot.scale);
  });

  const opts = {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: Easing.inOut(Easing.cubic),
  } as const;

  return {
    focusY: interpolate(frame, times, focus, opts),
    scale: interpolate(frame, times, scale, opts),
  };
};

/**
 * Escenario 9:16: el teléfono GRANDE (87 % del ancho) con banda oscura arriba
 * para el texto, dentro de la zona que Reels no tapa.
 *
 * Ni pequeño-en-medio-de-negro (el primer intento: 65 % de ancho y 36 % del
 * lienzo vacío, invisible en un feed) ni a sangre (el texto blanco cae sobre
 * las tarjetas blancas de la app y no se lee). El marco da sitio al texto
 * sobre fondo oscuro y deja el teléfono grande.
 *
 * La caja es MÁS CUADRADA que un iPhone a propósito: 940×1000 contra un origen
 * de 19,5:9. Ese recorte es lo que hace que la cámara tenga a dónde moverse.
 */
export const REELS_STAGE = {
  left: 70,
  top: 530,
  width: 940,
  height: 1000,
  radius: 56,
} as const;

/**
 * Dónde se sienta el texto en 9:16.
 *
 * **Todo el texto va ARRIBA**, y eso es una decisión, no una limitación de
 * maquetación: con 1300 px útiles entre las dos safe areas de Reels no caben
 * texto grande arriba + teléfono grande + texto grande abajo. Intentarlo hizo
 * que los rótulos de abajo taparan el botón Guardar, la lista de cuentas y la
 * fila de éxito — o sea, taparan justo lo que la pieza viene a demostrar.
 *
 * El reparto es: el texto TITULA, el teléfono DEMUESTRA.
 */
export const REELS_TEXT = { top: 230, bottom: 420 } as const;

/** Encuadre 16:9: el teléfono a la izquierda, la columna de texto a la derecha. */
export const WIDE_DEVICE = { height: 1000, top: 40, left: 190 } as const;
export const WIDE_COPY = { left: 760, right: 110 } as const;

export const canvasOf = (aspect: "9x16" | "16x9") =>
  aspect === "9x16" ? yala.canvas.reels : yala.canvas.youtube;
