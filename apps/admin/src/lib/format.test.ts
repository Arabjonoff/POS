import { describe, expect, it } from "vitest";

import { formatDate, formatDateTime, formatMoney, formatMoneyAmount, formatSomPlain } from "./format";

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

describe("formatDateTime", () => {
  it("shows Tashkent wall time", () => {
    expect(formatDateTime("2026-09-01T09:00:00Z")).toBe("01.09.2026 14:00");
    expect(formatDateTime("2026-10-14T19:30:00Z")).toBe("15.10.2026 00:30");
  });
});

describe("formatSomPlain", () => {
  it("is plain so'm for spreadsheets", () => {
    expect(formatSomPlain(9_900_000)).toBe("99000");
    expect(formatSomPlain(-125_050)).toBe("-1250,50");
    expect(formatSomPlain(5)).toBe("0,05");
  });
});
