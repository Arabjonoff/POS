import { describe, expect, it } from "vitest";

import { formatDate, formatMoney, formatMoneyAmount } from "./format";

describe("formatMoneyAmount", () => {
  it("groups so'm and keeps tiyin only when present", () => {
    expect(formatMoneyAmount(0)).toBe("0");
    expect(formatMoneyAmount(125_000_000)).toBe("1 250 000");
    expect(formatMoneyAmount(12_345_650)).toBe("123 456,50");
    expect(formatMoneyAmount(5)).toBe("0,05");
    expect(formatMoneyAmount(-990_000)).toBe("−9 900");
  });

  it("handles large sums", () => {
    expect(formatMoneyAmount(9_000_000_000_000)).toBe("90 000 000 000");
  });
});

describe("formatMoney", () => {
  it("adds the currency label", () => {
    expect(formatMoney(15_000_000, "so'm")).toBe("150 000 so'm");
  });
});

describe("formatDate", () => {
  it("formats API dates", () => {
    expect(formatDate("2026-10-15")).toBe("15.10.2026");
    expect(formatDate("2026-10-15T08:00:00Z")).toBe("15.10.2026");
  });
});
