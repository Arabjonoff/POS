/** Server Action natijasi (UI xatoni tarjima kaliti bilan ko'rsatadi). */
export type ActionError =
  | "phone_taken"
  | "invalid"
  | "not_found"
  | "only_latest_payment"
  | "unavailable";

export type ActionResult<T> =
  | { ok: true; data: T }
  | { ok: false; error: ActionError; fields?: string[] };

/** Django xatosi: `{"error": {"code", "message", "details"}}`. */
type DjangoError = { error?: { code?: string; details?: Record<string, unknown> } };

export function failure(status: number, body: unknown): { ok: false; error: ActionError; fields?: string[] } {
  const error = (body as DjangoError | undefined)?.error;
  if (error?.code === "phone_taken" || status === 409) return { ok: false, error: "phone_taken" };
  if (error?.code === "only_latest_payment") return { ok: false, error: "only_latest_payment" };
  if (status === 404) return { ok: false, error: "not_found" };
  if (status === 400) {
    const details = error?.details ?? {};
    const fields = Object.keys(details).flatMap((key) =>
      key === "owner" && details.owner && typeof details.owner === "object"
        ? Object.keys(details.owner).map((sub) => `owner.${sub}`)
        : [key],
    );
    return { ok: false, error: "invalid", fields };
  }
  return { ok: false, error: "unavailable" };
}
