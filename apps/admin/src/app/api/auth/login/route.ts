import { NextResponse } from "next/server";

import { setSessionCookies } from "@/lib/auth/cookies";
import { login } from "@/lib/auth/django";

export type LoginError = "invalid_credentials" | "not_admin" | "too_many_attempts" | "unavailable" | "bad_request";

function fail(error: LoginError, status: number) {
  return NextResponse.json({ error }, { status });
}

/** Telefon + parol → Django JWT → httpOnly cookie. Faqat `platform_admin`. */
export async function POST(request: Request) {
  const body: unknown = await request.json().catch(() => null);
  const { phone, password } = (body ?? {}) as Record<string, unknown>;
  if (typeof phone !== "string" || typeof password !== "string" || !phone || !password) {
    return fail("bad_request", 400);
  }
  let result;
  try {
    result = await login(phone, password);
  } catch {
    return fail("unavailable", 502);
  }
  if (!result.ok) {
    if (result.status === 429) return fail("too_many_attempts", 429);
    if (result.status === 400 || result.status === 401) return fail("invalid_credentials", 401);
    return fail("unavailable", 502);
  }
  if (result.user.role !== "platform_admin") return fail("not_admin", 403);
  const response = NextResponse.json({
    user: { id: result.user.id, fullName: result.user.full_name, phone: result.user.phone },
  });
  setSessionCookies(response.cookies, result.tokens);
  return response;
}
