import { describe, expect, it } from "vitest";

import { toCsv } from "./csv";

describe("toCsv", () => {
  it("escapes quotes, commas and new lines; adds BOM", () => {
    const csv = toCsv([
      ["Nomi", "Telefon"],
      ['Baraka "Plus"', "+998 90"],
      ["A, B", null],
      ["two\nlines", 5],
    ]);
    expect(csv).toBe(
      '﻿Nomi,Telefon\r\n"Baraka ""Plus""",+998 90\r\n"A, B",\r\n"two\nlines",5\r\n',
    );
  });
});
