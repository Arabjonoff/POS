/** Audit yozuvidagi o'zgarish: `before`/`after` JSON'lari orasidagi farq. */
export type FieldChange = { field: string; before: string; after: string };

function show(value: unknown): string {
  if (value === undefined) return "";
  if (value === null) return "null";
  return typeof value === "string" ? value : JSON.stringify(value);
}

/** O'zgargan maydonlar (yaratishda — barcha `after` maydonlari, `before` bo'sh). */
export function auditChanges(before: unknown, after: unknown): FieldChange[] {
  const b = before && typeof before === "object" ? (before as Record<string, unknown>) : {};
  const a = after && typeof after === "object" ? (after as Record<string, unknown>) : {};
  const fields = [...new Set([...Object.keys(b), ...Object.keys(a)])].sort();
  return fields
    .filter((field) => JSON.stringify(b[field]) !== JSON.stringify(a[field]))
    .map((field) => ({ field, before: show(b[field]), after: show(a[field]) }));
}
