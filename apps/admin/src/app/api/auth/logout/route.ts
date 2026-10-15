import { NextResponse } from "next/server";

import { clearSessionCookies } from "@/lib/auth/cookies";

/** Cookie'larni o'chiradi (Django refresh'i o'z muddati bilan eskiradi). */
export async function POST() {
  const response = new NextResponse(null, { status: 204 });
  clearSessionCookies(response.cookies);
  return response;
}
