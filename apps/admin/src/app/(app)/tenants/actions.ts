"use server";

import { revalidatePath } from "next/cache";
import { unstable_rethrow } from "next/navigation";

import { failure, type ActionResult } from "@/lib/action-result";
import { platformApi } from "@/lib/platform";

export type { ActionError, ActionResult } from "@/lib/action-result";

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

export type PaymentMethod = "cash" | "transfer" | "card" | "other";

/** To'lov kiritish → server muddatni uzaytiradi (`record_payment`). */
export async function recordPayment(
  tenantId: string,
  input: { amountTiyin: number; months: number; method: PaymentMethod; note: string },
): Promise<ActionResult<{ periodFrom: string; periodTo: string }>> {
  const api = await platformApi();
  try {
    const { data, error, response } = await api.POST("/api/v1/platform/tenants/{id}/payments/", {
      params: { path: { id: tenantId } },
      body: {
        amount_tiyin: input.amountTiyin,
        months: input.months,
        method: input.method,
        note: input.note.trim(),
      },
    });
    if (!data) return failure(response.status, error);
    revalidatePath(`/tenants/${tenantId}`);
    revalidatePath("/tenants");
    revalidatePath("/payments");
    revalidatePath("/");
    return { ok: true, data: { periodFrom: data.period_from, periodTo: data.period_to } };
  } catch (e) {
    unstable_rethrow(e);
    return { ok: false, error: "unavailable" };
  }
}

/** Oxirgi to'lovni bekor qilish (teskari yozuv; izoh majburiy). */
export async function reversePayment(paymentId: string, note: string): Promise<ActionResult<null>> {
  const api = await platformApi();
  try {
    const { data, error, response } = await api.POST("/api/v1/platform/payments/{id}/reverse/", {
      params: { path: { id: paymentId } },
      body: { note: note.trim() },
    });
    if (!data) return failure(response.status, error);
    revalidatePath(`/tenants/${data.tenant}`);
    revalidatePath("/payments");
    revalidatePath("/");
    return { ok: true, data: null };
  } catch (e) {
    unstable_rethrow(e);
    return { ok: false, error: "unavailable" };
  }
}
