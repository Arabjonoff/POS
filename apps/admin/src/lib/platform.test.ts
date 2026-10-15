// @vitest-environment node
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

import { PlatformApiError, getStats } from "./platform";

const jar = vi.hoisted(() => ({ access: "acc-1" as string | undefined }));

vi.mock("next/headers", () => ({
  cookies: async () => ({
    get: (name: string) => (name === "pos_access" && jar.access ? { value: jar.access } : undefined),
  }),
}));

vi.mock("next/navigation", () => ({
  redirect: (to: string) => {
    throw new Error(`redirect:${to}`);
  },
}));

beforeEach(() => {
  jar.access = "acc-1";
});
afterEach(() => vi.unstubAllGlobals());

describe("getStats", () => {
  it("calls Django with the admin's bearer token", async () => {
    const body = { tenants: { total: 1 }, mrr_tiyin: 0 };
    const fetch = vi.fn(async () => Response.json(body));
    vi.stubGlobal("fetch", fetch);
    expect(await getStats()).toEqual(body);
    const [request] = fetch.mock.calls[0] as unknown as [Request];
    expect(request.url).toMatch(/\/api\/v1\/platform\/stats\/$/);
    expect(request.headers.get("Authorization")).toBe("Bearer acc-1");
  });

  it("an expired session goes to the login page", async () => {
    vi.stubGlobal(
      "fetch",
      vi.fn(async () => Response.json({}, { status: 401 })),
    );
    await expect(getStats()).rejects.toThrow("redirect:/login");

    jar.access = undefined;
    await expect(getStats()).rejects.toThrow("redirect:/login");
  });

  it("server errors surface as PlatformApiError", async () => {
    vi.stubGlobal(
      "fetch",
      vi.fn(async () => Response.json({}, { status: 500 })),
    );
    await expect(getStats()).rejects.toBeInstanceOf(PlatformApiError);
  });
});
