/** Ekrandagi raqamlar (pul — tiyin, butun son; CLAUDE.md 1-qoida). */

const NBSP = " ";

function group(value: number): string {
  return String(value).replace(/\B(?=(\d{3})+(?!\d))/g, NBSP);
}

/** `125000000` → `1 250 000`, tiyin bo'lsa `1 250 000,50`. Manfiy — `−`. */
export function formatMoneyAmount(tiyin: number): string {
  const abs = Math.abs(Math.trunc(tiyin));
  const whole = Math.floor(abs / 100);
  const cents = abs % 100;
  const text = cents === 0 ? group(whole) : `${group(whole)},${String(cents).padStart(2, "0")}`;
  return tiyin < 0 ? `−${text}` : text;
}

/** Summa valyuta bilan: `1 250 000 so'm`. [currency] — tarjimadan. */
export function formatMoney(tiyin: number, currency: string): string {
  return `${formatMoneyAmount(tiyin)}${NBSP}${currency}`;
}

/** `2026-10-15` → `15.10.2026` (sana API'dan `YYYY-MM-DD`). */
export function formatDate(isoDate: string): string {
  const [year, month, day] = isoDate.slice(0, 10).split("-");
  return `${day}.${month}.${year}`;
}

/** Platforma vaqt zonasi — Toshkent (UTC+5, yozgi vaqt yo'q; kassadagi qaror 0007 kabi). */
const TASHKENT_OFFSET_MS = 5 * 60 * 60 * 1000;

/** ISO vaqt → `15.10.2026 14:30` (Toshkent vaqti). */
export function formatDateTime(iso: string): string {
  const t = new Date(new Date(iso).getTime() + TASHKENT_OFFSET_MS);
  const two = (n: number) => String(n).padStart(2, "0");
  return `${two(t.getUTCDate())}.${two(t.getUTCMonth() + 1)}.${t.getUTCFullYear()} ${two(t.getUTCHours())}:${two(t.getUTCMinutes())}`;
}

/** CSV uchun so'm: guruhlarsiz, `-1250,50` (Excel raqam sifatida o'qiydi). */
export function formatSomPlain(tiyin: number): string {
  const abs = Math.abs(Math.trunc(tiyin));
  const cents = abs % 100;
  const text = `${Math.floor(abs / 100)}${cents ? `,${String(cents).padStart(2, "0")}` : ""}`;
  return tiyin < 0 ? `-${text}` : text;
}
