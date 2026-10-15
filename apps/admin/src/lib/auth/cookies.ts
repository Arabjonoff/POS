import type { NextResponse } from "next/server";

import { ACCESS_COOKIE, ACCESS_MAX_AGE, REFRESH_COOKIE, REFRESH_MAX_AGE } from "./config";
import type { Tokens } from "./django";

type ResponseCookies = NextResponse["cookies"];

const base = {
  httpOnly: true,
  sameSite: "lax" as const,
  secure: process.env.NODE_ENV === "production" && process.env.COOKIE_INSECURE !== "1",
  path: "/",
};

export function setSessionCookies(cookies: ResponseCookies, tokens: Tokens): void {
  cookies.set(ACCESS_COOKIE, tokens.access, { ...base, maxAge: ACCESS_MAX_AGE });
  cookies.set(REFRESH_COOKIE, tokens.refresh, { ...base, maxAge: REFRESH_MAX_AGE });
}

export function clearSessionCookies(cookies: ResponseCookies): void {
  cookies.set(ACCESS_COOKIE, "", { ...base, maxAge: 0 });
  cookies.set(REFRESH_COOKIE, "", { ...base, maxAge: 0 });
}
