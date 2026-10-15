import { NextResponse, type NextRequest } from "next/server";

import { ACCESS_COOKIE, LOGIN_PATH, REFRESH_COOKIE } from "@/lib/auth/config";
import { clearSessionCookies, setSessionCookies } from "@/lib/auth/cookies";
import { refreshTokens, type Tokens } from "@/lib/auth/django";

/**
 * Optimistik tekshiruv (faqat cookie): kirmagan — `/login?next=...`.
 * Access eskirgan, refresh bor — Django'da yangilab, cookie'larni almashtiradi.
 * Haqiqiy tekshiruv — `(app)/layout.tsx` dagi `getCurrentAdmin()`.
 */
export async function proxy(request: NextRequest) {
  const { pathname, search } = request.nextUrl;
  const onLogin = pathname === LOGIN_PATH;
  const refresh = request.cookies.get(REFRESH_COOKIE)?.value;
  let access = request.cookies.get(ACCESS_COOKIE)?.value;

  let renewed: Tokens | null = null;
  let expired = false;
  if (!access && refresh) {
    renewed = await refreshTokens(refresh).catch(() => null);
    if (renewed) {
      access = renewed.access;
      // Shu so'rovning o'zi ham yangi token bilan render qilinsin.
      request.cookies.set(ACCESS_COOKIE, renewed.access);
      request.cookies.set(REFRESH_COOKIE, renewed.refresh);
    } else {
      expired = true;
    }
  }

  let response: NextResponse;
  if (!access && !onLogin) {
    const url = new URL(LOGIN_PATH, request.url);
    url.searchParams.set("next", `${pathname}${search}`);
    response = NextResponse.redirect(url);
  } else {
    response = NextResponse.next({ request: { headers: request.headers } });
  }
  if (renewed) setSessionCookies(response.cookies, renewed);
  if (expired) clearSessionCookies(response.cookies);
  return response;
}

export const config = {
  // API route'lar, Next fayllari va statik fayllar (nuqtali) — tekshirilmaydi.
  matcher: ["/((?!api|_next/static|_next/image|.*\..*).*)"],
};
