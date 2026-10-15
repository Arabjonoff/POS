import { describe, expect, it } from "vitest";

import { safeNext } from "./config";

describe("safeNext", () => {
  it("keeps internal paths only", () => {
    expect(safeNext("/tenants?q=1")).toBe("/tenants?q=1");
    expect(safeNext(undefined)).toBe("/");
    expect(safeNext("https://evil.example")).toBe("/");
    expect(safeNext("//evil.example")).toBe("/");
    expect(safeNext("/\\evil.example")).toBe("/");
    expect(safeNext("/login")).toBe("/");
  });
});
