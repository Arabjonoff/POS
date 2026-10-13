import { describe, expect, it } from "vitest";

import ru from "../../messages/ru.json";
import uz from "../../messages/uz.json";

import { resolveLocale } from "./config";

function keys(obj: object, prefix = ""): string[] {
  return Object.entries(obj).flatMap(([key, value]) =>
    typeof value === "object" && value !== null
      ? keys(value, `${prefix}${key}.`)
      : [`${prefix}${key}`],
  );
}

describe("translations", () => {
  it("uz and ru have the same keys", () => {
    expect(keys(ru).sort()).toEqual(keys(uz).sort());
  });

  it("has no empty strings", () => {
    for (const messages of [uz, ru]) {
      for (const key of keys(messages)) {
        const value = key.split(".").reduce<unknown>((acc, part) => (acc as Record<string, unknown>)[part], messages);
        expect(value, key).not.toBe("");
      }
    }
  });
});

describe("resolveLocale", () => {
  it("falls back to uz", () => {
    expect(resolveLocale(undefined)).toBe("uz");
    expect(resolveLocale("en")).toBe("uz");
    expect(resolveLocale("ru")).toBe("ru");
  });
});
