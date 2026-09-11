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

export type HookSpec = Cue & {
  /** Máximo 6 palabras. Si no cabe en un respiro, no es un hook. */
  text: Localized;
};

export type CalloutSpec = Cue & {
  text: Localized;
  /** `gasto` pinta el acento en rosa #FF0080, como en la app. */
  tone?: "neutral" | "gasto";
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
  /** Tema DEL MARCO. El footage nunca se recolorea. */
  theme: Theme;
  hook: HookSpec | null;
  callouts: CalloutSpec[];
  endCard: EndCardSpec | null;
  notes?: string;
};

const END_CARD: EndCardSpec = {
  durationSec: 1,
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
    // El status bar de esta toma lleva la píldora roja de ReplayKit los 16 s.
    // 0.05 se la lleva entera sin tocar la cabecera «Yala IA» (empieza en 6.5 %).
    crop: { top: 0.05 },
    theme: "dark",
    hook: {
      fromSec: 0.2,
      toSec: 1.4,
      text: { es: "Un gasto, en una frase", en: "One expense, one sentence" },
    },
    callouts: [
      {
        // Entra cuando el producto YA mostró el resultado, no antes.
        fromSec: 11.9,
        toSec: 13.9,
        tone: "gasto",
        text: {
          es: "La categoría, puesta sola",
          en: "Category filled in for you",
        },
      },
    ],
    endCard: END_CARD,
    notes:
      "Toma con deuda: tema Light y píldora de grabación. La siguiente va en Liquid Glass oscuro y con la status bar limpia.",
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
    hook: null,
    callouts: [],
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
