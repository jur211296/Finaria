import type { Theme } from "./tokens";
import { sec } from "../lib/timing";

/**
 * El guion de cada pieza. Ni una palabra del copy vive dentro del JSX:
 * la plantilla es un motor, esto es el contenido.
 *
 * Voz Yala (marketing/screenshots-appstore/captions.md): cercana, SIN regañar.
 * La gente no deja de llevar sus cuentas por falta de disciplina, sino por
 * fricción. Si una línea suena a reproche, está mal aunque convierta.
 */

export type Locale = "es" | "en";
export type Localized = Record<Locale, string>;

/** Tramo del guion, en segundos del footage. */
export type Cue = { fromSec: number; toSec: number };

/**
 * Un golpe de texto.
 *
 * En un feed el texto NO es un rótulo que asoma y se va: es el hilo que se lee
 * cuando el vídeo va SIN SONIDO, que es como se ve el 85 % de las veces. Una
 * pieza de 16 s lleva 6–8 beats, no uno. Si hay dos segundos sin texto, el
 * pulgar sigue bajando.
 */
export type Beat = Cue & {
  text: Localized;
  /** `hero` grita, `line` cuenta, `pill` etiqueta lo que acaba de pasar. */
  style: "hero" | "line" | "pill";
  place: "top" | "bottom";
  /** `gasto` pinta el acento en rosa #FF0080, como el monto en la app. */
  tone?: "neutral" | "gasto";
};

/**
 * Un plano de cámara sobre el footage. Esto es el «zoom al gesto»: la cámara
 * va a donde está pasando algo en vez de enseñar la pantalla entera, quieta,
 * durante dieciséis segundos.
 *
 * `focusY` = fracción del alto visible del footage que queda centrada.
 * `scale`  = 1 llena el ancho del lienzo; 1,4 es un primer plano.
 */
export type Shot = {
  atSec: number;
  focusY: number;
  scale: number;
};

export type EndCardSpec = { durationSec: number; line: Localized };

export type Piece = {
  slug: string;
  /** Nombre humano; es lo que se lee en la barra lateral del Studio. */
  title: string;
  /** Ruta dentro de `public/`. `null` = todavía no hay toma. */
  footage: string | null;
  /** Duración REAL del mp4, medida con ffprobe. No se estima. */
  footageSec: number;
  /** Resolución del origen, para encajarlo sin deformarlo. */
  source: { w: number; h: number };
  /** Fracción del origen que se recorta arriba/abajo. Ver SHOT-CARDS.md. */
  crop?: { top?: number; bottom?: number };
  /** Tema del fondo y los rótulos. El footage nunca se recolorea. */
  theme: Theme;
  /** El hilo de texto, en orden. */
  beats: Beat[];
  /** Los planos de cámara, en orden. */
  shots: Shot[];
  endCard: EndCardSpec | null;
  notes?: string;
};

const END_CARD: EndCardSpec = {
  durationSec: 1.6,
  line: {
    es: "Anotar un gasto toma segundos.",
    en: "Logging an expense takes seconds.",
  },
};

// ---------------------------------------------------------------------------
// PACK 2.1 — 8 héroes + 2 apoyos
// Los slugs sin toma quedan reservados con `footage: null`: el Studio los
// muestra con su cartel de «falta la toma» en vez de reventar. El copy de esos
// ocho sale del brief del pack, que NO se regenera desde aquí.
// ---------------------------------------------------------------------------

export const PIECES: Piece[] = [
  {
    slug: "ia-gasto-pizza",
    title: "Yala IA · gasto en lenguaje natural",
    footage: "footage/ia-gasto-pizza-16s.mp4",
    footageSec: 16.183,
    source: { w: 1170, h: 2532 },
    // Se recorta la status bar (píldora roja de grabación) y el pie de
    // «Yala IA puede cometer errores», que no aporta nada y roba altura.
    crop: { top: 0.05, bottom: 0.035 },
    theme: "dark",

    // El hilo. Ataca la FRICCIÓN, que es el posicionamiento entero: la gente
    // no deja las cuentas por vaga, las deja porque apuntarlas es un coñazo.
    beats: [
      {
        fromSec: 0.0,
        toSec: 2.1,
        style: "hero",
        place: "top",
        text: { es: "Sin formularios.", en: "No forms." },
      },
      {
        fromSec: 2.2,
        toSec: 3.7,
        style: "line",
        place: "top",
        text: { es: "Lo escribes como lo dirías", en: "Type it like you'd say it" },
      },
      {
        fromSec: 3.9,
        toSec: 5.7,
        style: "line",
        place: "top",
        text: { es: "Y la IA hace el resto", en: "The AI does the rest" },
      },
      {
        fromSec: 6.0,
        toSec: 7.9,
        style: "pill",
        place: "top",
        text: { es: "Monto · categoría · fecha", en: "Amount · category · date" },
      },
      {
        fromSec: 8.3,
        toSec: 11.1,
        style: "line",
        place: "top",
        text: { es: "Tú eliges la cuenta", en: "You pick the account" },
      },
      {
        // El golpe. Entra medio segundo DESPUÉS de que la fila de éxito
        // aparezca: si entra a la vez, parece que lo anuncia; entrando
        // después, lo confirma.
        fromSec: 11.8,
        toSec: 13.8,
        style: "hero",
        place: "top",
        tone: "gasto",
        text: { es: "Registrado.", en: "Logged." },
      },
      {
        fromSec: 14.2,
        toSec: 16.18,
        style: "line",
        place: "top",
        text: { es: "Tus cuentas, al día", en: "Your books, up to date" },
      },
    ],

    // La cámara. Cada plano mira donde está el gesto; los porcentajes salen de
    // medir el footage frame a frame con ffmpeg, no de estimarlos.
    shots: [
      // Cada `focusY` sale de localizar el elemento en el footage con ffmpeg y
      // pasarlo a fracción del trozo VISIBLE (el origen menos el crop):
      //   focusYVisible = (fracciónEnElOriginal − cropTop) / (1 − cropTop − cropBottom)
      // La ventana que se ve es 0,505 / scale del alto visible, así que subir
      // el zoom cierra el plano: por encima de ~1,25 empieza a cortar texto
      // por los lados.
      { atSec: 0.0, focusY: 0.4, scale: 1.02 }, // los tres chips
      { atSec: 1.7, focusY: 0.72, scale: 1.08 }, // el campo de texto ← el gesto
      { atSec: 3.9, focusY: 0.26, scale: 1.12 }, // la burbuja del usuario
      { atSec: 6.1, focusY: 0.49, scale: 1.0 }, // la card ENTERA: plano estrella
      { atSec: 8.4, focusY: 0.41, scale: 1.22 }, // la fila «Cuenta» cambiando
      { atSec: 10.1, focusY: 0.42, scale: 1.14 }, // ya dice «Gastos Soles · PEN»
      { atSec: 11.6, focusY: 0.34, scale: 1.18 }, // la fila de éxito
      { atSec: 14.1, focusY: 0.34, scale: 1.0 }, // se abre a la lista
      { atSec: 16.18, focusY: 0.38, scale: 1.1 }, // push lento de salida
    ],

    endCard: END_CARD,
    notes:
      "Toma con deuda: tema Light y píldora de grabación (tapada con crop). La siguiente va en Liquid Glass oscuro y con la status bar limpia.",
  },

  // --- 7 héroes restantes del pack 2.1: slugs reservados, sin toma ---
  reserved("voz-gasto-hablado", "Registra hablando"),
  reserved("foto-recibo", "Foto al recibo"),
  reserved("presupuestos", "Presupuestos que sí funcionan"),
  reserved("grupos-quien-debe", "Grupos · quién debe a quién"),
  reserved("flujo-de-caja", "Tu saldo del futuro"),
  reserved("salud-financiera", "Tu salud financiera en un número"),
  reserved("personalizacion", "Hazla tuya"),

  // --- 2 apoyos ---
  reserved("gastos-hormiga", "Apoyo · gastos hormiga"),
  reserved("privacidad", "Apoyo · tu dinero es privado"),

  // --- Explainer con voz en off: SLUG RESERVADO, sin composition ni render.
  // Se hace con la skill `anything2explainer` cuando Jürgen lo pida. Sin
  // ElevenLabs por ahora. Ver docs/OPERACION.md § Explainer.
  reserved("explainer-que-es-yala-ia", "Explainer · ¿qué es Yala IA?"),
];

function reserved(slug: string, title: string): Piece {
  return {
    slug,
    title,
    footage: null,
    footageSec: 8,
    source: { w: 1170, h: 2532 },
    theme: "dark",
    beats: [],
    shots: [{ atSec: 0, focusY: 0.5, scale: 1 }],
    endCard: END_CARD,
    notes: "Slug reservado del pack 2.1. Falta la toma y falta el copy del brief.",
  };
}

export const pieceBySlug = (slug: string): Piece => {
  const found = PIECES.find((p) => p.slug === slug);
  if (!found) {
    throw new Error(
      `No hay pieza con slug "${slug}". Las que hay: ${PIECES.map((p) => p.slug).join(", ")}`,
    );
  }
  return found;
};

/** Cuerpo + end card, en frames. Es lo que consume `calculateMetadata`. */
export const pieceDurationInFrames = (piece: Piece) =>
  sec(piece.footageSec) + sec(piece.endCard?.durationSec ?? 0);

export const PILOT = pieceBySlug("ia-gasto-pizza");
