import { describe, expect, it } from "vitest";

import { auditChanges } from "./audit";

describe("auditChanges", () => {
  it("lists only changed fields, sorted", () => {
    expect(
      auditChanges(
        { name: "Baraka", is_blocked: false, blocked_reason: "", address: "A" },
        { name: "Baraka", is_blocked: true, blocked_reason: "Qarz", address: "A" },
      ),
    ).toEqual([
      { field: "blocked_reason", before: "", after: "Qarz" },
      { field: "is_blocked", before: "false", after: "true" },
    ]);
  });

  it("creation: every field is new; nested values as JSON", () => {
    expect(auditChanges(null, { price: 9900000, features: { a: 1 } })).toEqual([
      { field: "features", before: "", after: '{"a":1}' },
      { field: "price", before: "", after: "9900000" },
    ]);
  });

  it("no snapshots → nothing", () => {
    expect(auditChanges(undefined, undefined)).toEqual([]);
  });
});
