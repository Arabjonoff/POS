// @vitest-environment node
import { NextRequest } from "next/server";
import { afterEach, describe, expect, it, vi } from "vitest";

import { proxy } from "./proxy";

function get(path: string, cookies: Record<string, string> = {}) {
  const cookie = Object.entries(cookies)
    .map(([k, v]) => `${k}=${v}`)
    .join("; ");
  return new NextRequest(`http://admin.test${path}`, { headers: cookie ? { cookie } : {} });
}

afterEach(() => vi.unstubAllGlobals());

describe("proxy", () => {
  it("sends anonymous visitors to the login page with a return path", async () => {
    const response = await proxy(get("/tenants?q=1"));
    expect(response.status).toBe(307);
    const location = new URL(response.headers.get("location")!);
    expect(location.pathname).toBe("/login");
    expect(location.searchParams.get("next")).toBe("/tenants?q=1");
  });

  it("lets the login page and signed-in admins through", async () => {
    expect((await proxy(get("/login"))).headers.get("x-middleware-next")).toBe("1");
    const response = await proxy(get("/", { pos_access: "a", pos_refresh: "r" }));
    expect(response.headers.get("x-middleware-next")).toBe("1");
  });

  it("refreshes an expired access token and forwards it", async () => {
    const fetch = vi.fn(async () => Response.json({ access: "new-a", refresh: "new-r" }));
    vi.stubGlobal("fetch", fetch);
    const response = await proxy(get("/devices", { pos_refresh: "old-r" }));
    expect(response.headers.get("x-middleware-next")).toBe("1");
    const cookies = response.headers.getSetCookie().join("\n");
    expect(cookies).toMatch(/pos_access=new-a/);
    expect(cookies).toMatch(/pos_refresh=new-r/);
    // So'rovning o'zi ham yangi token bilan (server komponentlar uchun).
    expect(response.headers.get("x-middleware-request-cookie")).toMatch(/pos_access=new-a/);
    const [, init] = fetch.mock.calls[0] as unknown as [string, RequestInit];
    expect(JSON.parse(String(init.body))).toEqual({ refresh: "old-r" });
  });

  it("an invalid refresh token clears cookies and goes to login", async () => {
    vi.stubGlobal(
      "fetch",
      vi.fn(async () => Response.json({ detail: "bad" }, { status: 401 })),
    );
    const response = await proxy(get("/", { pos_refresh: "expired" }));
    expect(response.status).toBe(307);
    expect(response.headers.getSetCookie().join("\n")).toMatch(/pos_refresh=;.*Max-Age=0/i);
  });
});
