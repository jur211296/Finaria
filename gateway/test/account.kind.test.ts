/**
 * Unit OFFLINE de `kind` en `/account/exists` y `/account/claim` (g15_01) — 100% sin red, molde de
 * `account.delete.test.ts`. Se mockea `verifyUserToken` (evita el JWKS remoto de jose) y se stubbea
 * `fetch`; `getRows` y `callRpc` quedan REALES, así que el `select=` y el cuerpo del RPC que viajan
 * son los de verdad.
 *
 * POR QUÉ ESTE FICHERO EXISTE. Antes de g15_01, `/account/exists` y `/account/claim` NO tenían un solo
 * test offline: su única cobertura eran los goldens contra staging real, que necesitan red y las
 * contraseñas de los dos usuarios de test. Lo que aquí se fija —el `select=` que se le pide a
 * PostgREST, el trato de un `kind` desconocido, y que `p_kind` viaje al RPC— es justo lo que un
 * golden NO puede distinguir de un fallo de entorno.
 *
 * El contrato de ausencia es el que carga el peso: `kind` AUSENTE en la respuesta significa
 * `groups_only` para el cliente (fail-safe hacia lo menos invasivo, decisión de Jürgen del
 * 2026-09-09). Por eso un valor fuera del dominio se OMITE en vez de reenviarse: el cliente lo
 * guardaría en su caché sellada y no tendría de qué corregirse.
 */
import { afterEach, describe, expect, it, vi } from "vitest";
import type { Env } from "../src/env";

const SUB = "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee";
const VALID = "valid-user-jwt";

vi.mock("../src/sync/userauth", async (importOriginal) => {
  const actual = await importOriginal<typeof import("../src/sync/userauth")>();
  return {
    ...actual,
    verifyUserToken: vi.fn(async (_env: Env, token: string) =>
      token === VALID ? { sub: SUB, token } : null,
    ),
  };
});

const { default: app } = await import("../src/index");

const SUPA = "https://kind-unit.local";

function makeEnv(overrides: Partial<Env> = {}): Env {
  return {
    ENVIRONMENT: "staging",
    ENFORCE: "observe",
    SUPABASE_URL: SUPA,
    SUPABASE_ANON_KEY: "anon-key-unit",
    ...overrides,
  } as unknown as Env;
}

interface Captura {
  urls: string[];
  rpcBodies: unknown[];
}

/** Stub de fetch que CAPTURA la URL del GET a profiles y el body del RPC. */
function stubFetch(res: { status: number; body: unknown }): Captura {
  const cap: Captura = { urls: [], rpcBodies: [] };
  vi.stubGlobal(
    "fetch",
    vi.fn(async (input: unknown, init?: RequestInit) => {
      const url = typeof input === "string" ? input : ((input as Request).url ?? String(input));
      cap.urls.push(url);
      if (url.includes("/rest/v1/rpc/claim_account")) {
        cap.rpcBodies.push(JSON.parse(String(init?.body ?? "{}")));
      }
      return new Response(JSON.stringify(res.body), {
        status: res.status,
        headers: { "content-type": "application/json" },
      });
    }),
  );
  return cap;
}

async function exists(env: Env): Promise<Response> {
  return await app.fetch(
    new Request("https://gw.local/account/exists", {
      method: "GET",
      headers: { Authorization: `Bearer ${VALID}` },
    }),
    env,
  );
}

async function claim(env: Env, body: Record<string, unknown>): Promise<Response> {
  return await app.fetch(
    new Request("https://gw.local/account/claim", {
      method: "POST",
      headers: { Authorization: `Bearer ${VALID}`, "Content-Type": "application/json" },
      body: JSON.stringify(body),
    }),
    env,
  );
}

afterEach(() => {
  vi.unstubAllGlobals();
});

describe("GET /account/exists · kind", () => {
  it("pide la columna kind a PostgREST (si no, el resto de este fichero mide una respuesta inventada)", async () => {
    const cap = stubFetch({ status: 200, body: [{ id: SUB, kind: "complete" }] });
    await exists(makeEnv());
    expect(cap.urls.some((u) => u.includes("select=id%2Ckind") || u.includes("select=id,kind"))).toBe(true);
  });

  it("cuenta completa → { exists: true, kind: 'complete' }", async () => {
    stubFetch({ status: 200, body: [{ id: SUB, kind: "complete" }] });
    const res = await exists(makeEnv());
    expect(res.status).toBe(200);
    expect(await res.json()).toEqual({ exists: true, kind: "complete" });
  });

  it("cuenta de solo grupos → { exists: true, kind: 'groups_only' }", async () => {
    stubFetch({ status: 200, body: [{ id: SUB, kind: "groups_only" }] });
    expect(await (await exists(makeEnv())).json()).toEqual({ exists: true, kind: "groups_only" });
  });

  it("cuenta inexistente → { exists: false } y SIN kind", async () => {
    stubFetch({ status: 200, body: [] });
    const cuerpo = (await (await exists(makeEnv())).json()) as Record<string, unknown>;
    expect(cuerpo).toEqual({ exists: false });
    expect("kind" in cuerpo).toBe(false);
  });

  it("kind desconocido → se OMITE, no se reenvía (el cliente lo cachearía y no se corregiría)", async () => {
    stubFetch({ status: 200, body: [{ id: SUB, kind: "premium_deluxe" }] });
    const cuerpo = (await (await exists(makeEnv())).json()) as Record<string, unknown>;
    expect(cuerpo).toEqual({ exists: true });
    expect("kind" in cuerpo).toBe(false);
  });

  it("fila sin columna kind (base sin migrar) → exists sigue contestando true, sin kind", async () => {
    stubFetch({ status: 200, body: [{ id: SUB }] });
    expect(await (await exists(makeEnv())).json()).toEqual({ exists: true });
  });

  it("upstream caído → 502, nunca un exists inventado", async () => {
    stubFetch({ status: 500, body: { message: "boom" } });
    const res = await exists(makeEnv());
    expect(res.status).toBe(502);
  });
});

describe("POST /account/claim · kind", () => {
  const OK = { status: 200, body: { state: "created", kind: "complete" } };

  it("sin kind en el body → manda p_kind='complete' (el contrato de todos los llamadores de hoy)", async () => {
    const cap = stubFetch(OK);
    await claim(makeEnv(), { device_id: "d1", provider: "apple" });
    expect(cap.rpcBodies[0]).toMatchObject({ p_device_id: "d1", p_provider: "apple", p_kind: "complete" });
  });

  it("kind='groups_only' viaja al RPC tal cual", async () => {
    const cap = stubFetch({ status: 200, body: { state: "created", kind: "groups_only" } });
    await claim(makeEnv(), { device_id: "d1", provider: "google", kind: "groups_only" });
    expect(cap.rpcBodies[0]).toMatchObject({ p_kind: "groups_only" });
  });

  it("kind fuera del dominio → 400 legible, y el RPC NI SE LLAMA", async () => {
    const cap = stubFetch(OK);
    const res = await claim(makeEnv(), { device_id: "d1", provider: "apple", kind: "complet" });
    expect(res.status).toBe(400);
    expect(cap.rpcBodies.length).toBe(0);
  });

  it("kind no-string → 400 (un 42501 del RPC saldría como 502 y ocultaría el motivo)", async () => {
    const cap = stubFetch(OK);
    expect((await claim(makeEnv(), { device_id: "d1", provider: "apple", kind: 7 })).status).toBe(400);
    expect(cap.rpcBodies.length).toBe(0);
  });

  it("el kind del RPC se devuelve al cliente sin tocarlo (passthrough)", async () => {
    stubFetch({ status: 200, body: { state: "existing_stable", kind: "groups_only", profile: { provider: "apple" } } });
    const cuerpo = (await (await claim(makeEnv(), { device_id: "d1", provider: "apple" })).json()) as Record<string, unknown>;
    expect(cuerpo.state).toBe("existing_stable");
    expect(cuerpo.kind).toBe("groups_only");
  });

  it("device_id/provider siguen siendo obligatorios (el kind no relaja la validación de antes)", async () => {
    const cap = stubFetch(OK);
    expect((await claim(makeEnv(), { provider: "apple", kind: "complete" })).status).toBe(400);
    expect(cap.rpcBodies.length).toBe(0);
  });
});
