import { cookies } from "next/headers";
import { redirect } from "next/navigation";
import { cache } from "react";

import { ACCESS_COOKIE, LOGIN_PATH, type Admin } from "./config";
import { fetchMe } from "./django";

/**
 * Joriy platforma admini (Django `auth/me/` orqali). Kirmagan, token yaroqsiz
 * yoki admin emas — kirish sahifasiga. Bitta render ichida bir marta so'raladi.
 */
export const getCurrentAdmin = cache(async (): Promise<Admin> => {
  const access = (await cookies()).get(ACCESS_COOKIE)?.value;
  if (!access) redirect(LOGIN_PATH);
  const me = await fetchMe(access);
  if (!me || me.role !== "platform_admin") redirect(LOGIN_PATH);
  return { id: me.id, fullName: me.full_name, phone: me.phone };
});
