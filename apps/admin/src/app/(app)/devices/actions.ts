"use server";

import { revalidatePath } from "next/cache";
import { unstable_rethrow } from "next/navigation";

import { failure, type ActionResult } from "@/lib/action-result";
import { platformApi } from "@/lib/platform";

/** Qurilmani bloklash (sabab majburiy) — kassa sinxroni to'xtaydi. */
export async function blockDevice(id: string, reason: string): Promise<ActionResult<null>> {
  const api = await platformApi();
  try {
    const { data, error, response } = await api.POST("/api/v1/platform/devices/{id}/block/", {
      params: { path: { id } },
      body: { reason: reason.trim() },
    });
    if (!data) return failure(response.status, error);
    revalidatePath("/devices");
    return { ok: true, data: null };
  } catch (e) {
    unstable_rethrow(e);
    return { ok: false, error: "unavailable" };
  }
}

export async function unblockDevice(id: string, reason: string): Promise<ActionResult<null>> {
  const api = await platformApi();
  try {
    const { data, error, response } = await api.POST("/api/v1/platform/devices/{id}/unblock/", {
      params: { path: { id } },
      body: { reason: reason.trim() },
    });
    if (!data) return failure(response.status, error);
    revalidatePath("/devices");
    return { ok: true, data: null };
  } catch (e) {
    unstable_rethrow(e);
    return { ok: false, error: "unavailable" };
  }
}
