import { describe, expect, it } from "vitest";

import { addMonths, parseSom, previewPeriod, tashkentToday } from "./billing";

describe("addMonths (backend apps/billing/status.py bilan bir xil)", () => {
  it.each([
    ["2026-01-31", 1, "2026-02-28"],
    ["2028-01-31", 1, "2028-02-29"],
    ["2026-10-15", 1, "2026-11-15"],
    ["2026-11-30", 3, "2027-02-28"],
    ["2026-12-31", 12, "2027-12-31"],
    ["2026-03-31", -1, "2026-02-28"],
  ])("%s + %i → %s", (from, months, expected) => {
    expect(addMonths(from, months)).toBe(expected);
  });
});

describe("previewPeriod", () => {
  const today = "2026-10-15";

  it("starts from today when nothing is paid and the trial is over", () => {
    expect(previewPeriod({ paid_until: null, trial_ends_at: "2026-10-01" }, 1, today)).toEqual({
      from: "2026-10-15",
      to: "2026-11-15",
    });
  });

  it("paying during the trial starts after the trial (Q-002: B)", () => {
    expect(previewPeriod({ paid_until: null, trial_ends_at: "2026-10-25" }, 2, today)).toEqual({
      from: "2026-10-25",
      to: "2026-12-25",
    });
  });

  it("extends an active subscription from paid_until", () => {
    expect(previewPeriod({ paid_until: "2026-11-30", trial_ends_at: "2026-09-15" }, 3, today)).toEqual({
      from: "2026-11-30",
      to: "2027-02-28",
    });
  });

  it("an expired subscription restarts today", () => {
    expect(previewPeriod({ paid_until: "2026-08-31" }, 1, today)).toEqual({
      from: "2026-10-15",
      to: "2026-11-15",
    });
  });
});

describe("tashkentToday", () => {
  it("uses UTC+5", () => {
    expect(tashkentToday(new Date("2026-10-14T18:59:00Z"))).toBe("2026-10-14");
    expect(tashkentToday(new Date("2026-10-14T19:00:00Z"))).toBe("2026-10-15");
  });
});

describe("parseSom", () => {
  it("turns so'm text into whole tiyin", () => {
    expect(parseSom("99 000")).toBe(9_900_000);
    expect(parseSom("99 000")).toBe(9_900_000);
    expect(parseSom("1 250,5")).toBe(125_050);
    expect(parseSom("1250.05")).toBe(125_005);
    expect(parseSom("0")).toBe(0);
  });

  it("rejects garbage, negatives and 3 decimals", () => {
    expect(parseSom("")).toBeNull();
    expect(parseSom("-5")).toBeNull();
    expect(parseSom("12,345")).toBeNull();
    expect(parseSom("abc")).toBeNull();
  });
});
