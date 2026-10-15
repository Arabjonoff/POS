// @vitest-environment node
import { afterEach, describe, expect, it, vi } from "vitest";

import { fetchWithLength } from "./client";

afterEach(() => vi.unstubAllGlobals());

describe("fetchWithLength", () => {
  it("sends the body as text so Django gets a Content-Length", async () => {
    const fetch = vi.fn(async () => new Response("{}"));
    vi.stubGlobal("fetch", fetch);
    await fetchWithLength(
      new Request("http://backend:8000/api/v1/auth/login/", {
        method: "POST",
        headers: { "Content-Type": "application/json", Authorization: "Bearer t" },
        body: JSON.stringify({ phone: "1" }),
      }),
    );
    const [url, init] = fetch.mock.calls[0] as unknown as [string, RequestInit];
    expect(url).toBe("http://backend:8000/api/v1/auth/login/");
    expect(init.method).toBe("POST");
    expect(init.body).toBe('{"phone":"1"}');
    expect(new Headers(init.headers).get("Authorization")).toBe("Bearer t");
  });

  it("GET has no body", async () => {
    const fetch = vi.fn(async () => new Response("{}"));
    vi.stubGlobal("fetch", fetch);
    await fetchWithLength(new Request("http://backend:8000/api/health/"));
    const [, init] = fetch.mock.calls[0] as unknown as [string, RequestInit];
    expect(init.body).toBeUndefined();
  });
});
