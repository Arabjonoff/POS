// @vitest-environment node
import { afterEach, describe, expect, it, vi } from "vitest";

import { POST } from "./route";

function djangoReply(status: number, body: unknown) {
  return vi.fn(async () => Response.json(body, { status }));
}

function user(role: string) {
  return { id: "u1", phone: "+998901234567", full_name: "Admin", role, tenant: null };
}

function request(body: unknown) {
  return new Request("http://admin.test/api/auth/login", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });
}

afterEach(() => vi.unstubAllGlobals());

describe("POST /api/auth/login", () => {
  it("sets httpOnly cookies for a platform admin", async () => {
    const fetch = djangoReply(200, { access: "acc", refresh: "ref", user: user("platform_admin") });
    vi.stubGlobal("fetch", fetch);
    const response = await POST(request({ phone: "90 123 45 67", password: "secret" }));
    expect(response.status).toBe(200);
    expect(await response.json()).toEqual({
      user: { id: "u1", fullName: "Admin", phone: "+998901234567" },
    });
    const cookies = response.headers.getSetCookie();
    expect(cookies).toHaveLength(2);
    expect(cookies[0]).toMatch(/^pos_access=acc;.*HttpOnly/i);
    expect(cookies[1]).toMatch(/^pos_refresh=ref;.*HttpOnly/i);
    expect(cookies.join()).toMatch(/SameSite=lax/i);
    const [url, init] = fetch.mock.calls[0] as unknown as [string, RequestInit];
    expect(url).toMatch(/\/api\/v1\/auth\/login\/$/);
    // Tana — matn (Content-Length bilan), oqim emas: Django chunked'ni o'qimaydi.
    expect(typeof init.body).toBe("string");
    expect(JSON.parse(String(init.body))).toEqual({ phone: "90 123 45 67", password: "secret" });
  });

  it("rejects wrong credentials without cookies", async () => {
    vi.stubGlobal("fetch", djangoReply(401, { error: { code: "invalid_credentials" } }));
    const response = await POST(request({ phone: "901234567", password: "bad" }));
    expect(response.status).toBe(401);
    expect(await response.json()).toEqual({ error: "invalid_credentials" });
    expect(response.headers.getSetCookie()).toEqual([]);
  });

  it("rejects shop owners: the panel is for platform admins only", async () => {
    vi.stubGlobal("fetch", djangoReply(200, { access: "a", refresh: "r", user: user("owner") }));
    const response = await POST(request({ phone: "901234567", password: "x" }));
    expect(response.status).toBe(403);
    expect(await response.json()).toEqual({ error: "not_admin" });
    expect(response.headers.getSetCookie()).toEqual([]);
  });

  it("maps throttling, network errors and bad input", async () => {
    vi.stubGlobal("fetch", djangoReply(429, {}));
    expect((await POST(request({ phone: "1", password: "x" }))).status).toBe(429);

    vi.stubGlobal(
      "fetch",
      vi.fn(async () => Promise.reject(new TypeError("offline"))),
    );
    const offline = await POST(request({ phone: "1", password: "x" }));
    expect(offline.status).toBe(502);
    expect(await offline.json()).toEqual({ error: "unavailable" });

    expect((await POST(request({ phone: "", password: "x" }))).status).toBe(400);
  });
});
