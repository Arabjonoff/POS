"use server";

import { revalidatePath } from "next/cache";
import { unstable_rethrow } from "next/navigation";

import { failure, type ActionResult } from "@/lib/action-result";
import { platformApi } from "@/lib/platform";

export type PlanInput = {
  name: string;
  priceTiyin: number;
  maxDevices: number;
  maxUsers: number;
  isActive: boolean;
};

function body(input: PlanInput) {
  return {
    name: input.name.trim(),
    price_tiyin_per_month: input.priceTiyin,
    max_devices: input.maxDevices,
    max_users: input.maxUsers,
    is_active: input.isActive,
  };
}

/** Yangi tarif yoki tahrirlash (`id` bilan). */
export async function savePlan(id: string | null, input: PlanInput): Promise<ActionResult<null>> {
  const api = await platformApi();
  try {
    const { data, error, response } = id
      ? await api.PATCH("/api/v1/platform/plans/{id}/", { params: { path: { id } }, body: body(input) })
      : await api.POST("/api/v1/platform/plans/", { body: body(input) });
    if (!data) return failure(response.status, error);
    revalidatePath("/plans");
    return { ok: true, data: null };
  } catch (e) {
    unstable_rethrow(e);
    return { ok: false, error: "unavailable" };
  }
}

/** Tarif o'chirilmaydi — nofaol bo'ladi, obunalar saqlanadi. */
export async function deactivatePlan(id: string): Promise<ActionResult<null>> {
  const api = await platformApi();
  try {
    const { error, response } = await api.DELETE("/api/v1/platform/plans/{id}/", {
      params: { path: { id } },
    });
    if (!response.ok) return failure(response.status, error);
    revalidatePath("/plans");
    return { ok: true, data: null };
  } catch (e) {
    unstable_rethrow(e);
    return { ok: false, error: "unavailable" };
  }
}
