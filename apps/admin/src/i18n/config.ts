export const locales = ["uz", "ru"] as const;
export type Locale = (typeof locales)[number];
export const defaultLocale: Locale = "uz";
export const LOCALE_COOKIE = "locale";

export function resolveLocale(value: string | undefined | null): Locale {
  return locales.includes(value as Locale) ? (value as Locale) : defaultLocale;
}

/** Brauzerda tanlangan tilni cookie'ga yozadi (server keyingi so'rovda o'qiydi). */
export function persistLocale(locale: Locale): void {
  document.cookie = `${LOCALE_COOKIE}=${locale}; path=/; max-age=31536000; samesite=lax`;
}
