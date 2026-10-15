/** Django JWT'lari httpOnly cookie'larda (brauzer JavaScript'i ko'rmaydi). */
export const ACCESS_COOKIE = "pos_access";
export const REFRESH_COOKIE = "pos_refresh";

/** Django: access 30 daqiqa, refresh 30 kun (`SIMPLE_JWT`). Cookie biroz oldin eskiradi. */
export const ACCESS_MAX_AGE = 29 * 60;
export const REFRESH_MAX_AGE = 30 * 24 * 60 * 60;

/** Kirgan platforma admini (UI uchun). */
export type Admin = { id: string; fullName: string; phone: string | null };

export const LOGIN_PATH = "/login";

/** Kirishdan keyin qaytish manzili: faqat shu saytning ichki yo'li. */
export function safeNext(value: string | null | undefined): string {
  if (!value || !value.startsWith("/") || value.startsWith("//") || value.startsWith("/\\")) {
    return "/";
  }
  return value === LOGIN_PATH ? "/" : value;
}
