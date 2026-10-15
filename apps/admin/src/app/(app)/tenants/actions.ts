"use server";

import { revalidatePath } from "next/cache";
import { unstable_rethrow } from "next/navigation";

import { platformApi } from "@/lib/platform";

/** Django xatosi: `{"error": {"code", "message", "details"}}`. */
type DjangoError = { error?: { code?: string; details?: Record<string, unknown> } };

export type ActionError = "phone_taken" | "invalid" | "not_found" | "unavailable";

export type ActionResult<T> =
  | { ok: true; data: T }
  | { ok: false; error: ActionError; fields?: string[] };

function failure(status: number, body: unknown): { ok: false; error: ActionError; fields?: string[] } {
  const error = (body as DjangoError | undefined)?.error;
  if (error?.code === "phone_taken" || status === 409) return { ok: false, error: "phone_taken" };
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

export type OnboardInput = {
  name: string;
  address: string;
  notes: string;
  ownerPhone: string;
  ownerName: string;
  /** Bo'sh — server vaqtinchalik parol yaratadi. */
  ownerPassword: string;
  plan: string;
  trialDays: number;
};

export type OnboardOutput = {
  tenantId: string;
  tenantName: string;
  ownerPhone: string;
  ownerName: string;
  temporaryPassword: string | null;
};

/** Yangi mijoz: do'kon + ega + sinov obunasi (bitta tranzaksiya, serverda). */
export async function onboardTenant(input: OnboardInput): Promise<ActionResult<OnboardOutput>> {
  const api = await platformApi();
  try {
    const { data, error, response } = await api.POST("/api/v1/platform/tenants/", {
      body: {
        name: input.name.trim(),
        address: input.address.trim(),
        notes: input.notes.trim(),
        owner: {
          phone: input.ownerPhone.trim(),
          full_name: input.ownerName.trim(),
          ...(input.ownerPassword ? { password: input.ownerPassword } : {}),
        },
        plan: input.plan,
        trial_days: input.trialDays,
      },
    });
    if (!data) return failure(response.status, error);
    revalidatePath("/tenants");
    revalidatePath("/");
    return {
      ok: true,
      data: {
        tenantId: data.tenant.id ?? "",
        tenantName: data.tenant.name,
        ownerPhone: data.owner.phone ?? input.ownerPhone,
        ownerName: data.owner.full_name,
        temporaryPassword: data.temporary_password,
      },
    };
  } catch (e) {
    // `redirect()` (sessiya tugagan) yutilmasin.
    unstable_rethrow(e);
    return { ok: false, error: "unavailable" };
  }
}

export async function blockTenant(id: string, reason: string): Promise<ActionResult<null>> {
  const api = await platformApi();
  try {
    const { data, error, response } = await api.POST("/api/v1/platform/tenants/{id}/block/", {
      params: { path: { id } },
      body: { reason: reason.trim() },
    });
    if (!data) return failure(response.status, error);
    revalidatePath(`/tenants/${id}`);
    revalidatePath("/tenants");
    return { ok: true, data: null };
  } catch (e) {
    // `redirect()` (sessiya tugagan) yutilmasin.
    unstable_rethrow(e);
    return { ok: false, error: "unavailable" };
  }
}

export async function unblockTenant(id: string, reason: string): Promise<ActionResult<null>> {
  const api = await platformApi();
  try {
    const { data, error, response } = await api.POST("/api/v1/platform/tenants/{id}/unblock/", {
      params: { path: { id } },
      body: { reason: reason.trim() },
    });
    if (!data) return failure(response.status, error);
    revalidatePath(`/tenants/${id}`);
    revalidatePath("/tenants");
    return { ok: true, data: null };
  } catch (e) {
    // `redirect()` (sessiya tugagan) yutilmasin.
    unstable_rethrow(e);
    return { ok: false, error: "unavailable" };
  }
}

/** Ega/menejer paroli: yangi vaqtinchalik parol (faqat shu javobda). */
export async function resetUserPassword(userId: string): Promise<ActionResult<string>> {
  const api = await platformApi();
  try {
    const { data, error, response } = await api.POST("/api/v1/platform/users/{id}/reset-password/", {
      params: { path: { id: userId } },
    });
    if (!data) return failure(response.status, error);
    return { ok: true, data: data.temporary_password };
  } catch (e) {
    // `redirect()` (sessiya tugagan) yutilmasin.
    unstable_rethrow(e);
    return { ok: false, error: "unavailable" };
  }
}
