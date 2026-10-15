/**
 * Obuna to'lovi davri — serverdagi `apps/billing` bilan bir xil (subscription-billing.md):
 * `period_from = max(paid_until, trial_ends_at, bugun)`, `period_to = period_from + oylar`
 * (oy oxiri qisqartiriladi: 31-yanvar + 1 oy = 28/29-fevral). Faqat oldindan ko'rsatish
 * uchun — haqiqiy hisobni server qiladi.
 */

/** `YYYY-MM-DD` sanalar (kun, vaqt zonasisiz). */
export type IsoDate = string;

function parts(value: IsoDate): [number, number, number] {
  const [y, m, d] = value.slice(0, 10).split("-").map(Number);
  return [y, m, d];
}

function iso(year: number, month: number, day: number): IsoDate {
  return `${String(year).padStart(4, "0")}-${String(month).padStart(2, "0")}-${String(day).padStart(2, "0")}`;
}

function daysInMonth(year: number, month: number): number {
  return new Date(Date.UTC(year, month, 0)).getUTCDate();
}

/** Oy qo'shish; kun yangi oyda bo'lmasa — oy oxiri. */
export function addMonths(value: IsoDate, months: number): IsoDate {
  const [y, m, d] = parts(value);
  const index = m - 1 + months;
  const year = y + Math.floor(index / 12);
  const month = (((index % 12) + 12) % 12) + 1;
  return iso(year, month, Math.min(d, daysInMonth(year, month)));
}

/** Toshkent bo'yicha bugungi sana (UTC+5, yozgi vaqt yo'q). */
export function tashkentToday(now: Date = new Date()): IsoDate {
  const t = new Date(now.getTime() + 5 * 60 * 60 * 1000);
  return iso(t.getUTCFullYear(), t.getUTCMonth() + 1, t.getUTCDate());
}

export function previewPeriod(
  subscription: { paid_until: IsoDate | null; trial_ends_at?: IsoDate | null },
  months: number,
  today: IsoDate,
): { from: IsoDate; to: IsoDate } {
  const candidates = [today, subscription.paid_until, subscription.trial_ends_at].filter(
    (d): d is IsoDate => Boolean(d),
  );
  // `YYYY-MM-DD` satrlari leksikografik tartibda sana tartibi bilan bir xil.
  const from = candidates.reduce((a, b) => (b > a ? b : a));
  return { from, to: addMonths(from, months) };
}

/**
 * So'm matni → tiyin (butun son): `99 000` → 9 900 000, `1 250,5` → 125 050.
 * Noto'g'ri yoki manfiy — `null`. `float` ishlatilmaydi.
 */
export function parseSom(text: string): number | null {
  const clean = text.replace(/[\s ]/g, "").replace(".", ",");
  const match = /^(\d+)(?:,(\d{1,2}))?$/.exec(clean);
  if (!match) return null;
  const whole = Number(match[1]);
  const cents = Number((match[2] ?? "0").padEnd(2, "0"));
  const tiyin = whole * 100 + cents;
  return Number.isSafeInteger(tiyin) ? tiyin : null;
}
