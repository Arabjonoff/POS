import { screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

import { renderWithIntl } from "@/test-utils";

import { LoginForm } from "../login-form";

const router = vi.hoisted(() => ({ replace: vi.fn(), refresh: vi.fn(), push: vi.fn() }));

vi.mock("next/navigation", () => ({ useRouter: () => router, usePathname: () => "/login" }));

function reply(status: number, body: unknown) {
  return vi.fn(async () => Response.json(body, { status }));
}

async function fill(phone: string, password: string) {
  const user = userEvent.setup();
  await user.type(screen.getByLabelText("Telefon"), phone);
  await user.type(screen.getByLabelText("Parol"), password);
  await user.click(screen.getByRole("button", { name: "Kirish" }));
}

beforeEach(() => vi.clearAllMocks());
afterEach(() => vi.unstubAllGlobals());

describe("LoginForm", () => {
  it("asks for both fields without calling the server", async () => {
    const fetch = vi.fn();
    vi.stubGlobal("fetch", fetch);
    renderWithIntl(<LoginForm next="/" />);
    await userEvent.setup().click(screen.getByRole("button", { name: "Kirish" }));
    expect(screen.getByRole("alert")).toHaveTextContent("Telefon va parolni kiriting");
    expect(fetch).not.toHaveBeenCalled();
  });

  it("shows a plain message for a wrong password", async () => {
    vi.stubGlobal("fetch", reply(401, { error: "invalid_credentials" }));
    renderWithIntl(<LoginForm next="/" />);
    await fill("90 123 45 67", "bad");
    expect(await screen.findByRole("alert")).toHaveTextContent("Telefon yoki parol noto'g'ri");
    expect(router.replace).not.toHaveBeenCalled();
  });

  it("explains that a shop owner cannot use the panel", async () => {
    vi.stubGlobal("fetch", reply(403, { error: "not_admin" }));
    renderWithIntl(<LoginForm next="/" />, "ru");
    const user = userEvent.setup();
    await user.type(screen.getByLabelText("Телефон"), "901234567");
    await user.type(screen.getByLabelText("Пароль"), "x");
    await user.click(screen.getByRole("button", { name: "Войти" }));
    expect(await screen.findByRole("alert")).toHaveTextContent(
      "Эта учётная запись не для админ-панели",
    );
  });

  it("goes to the requested page after a successful login", async () => {
    const fetch = reply(200, { user: { id: "u1", fullName: "Admin", phone: null } });
    vi.stubGlobal("fetch", fetch);
    renderWithIntl(<LoginForm next="/tenants" />);
    await fill(" 90 123 45 67 ", "secret");
    await waitFor(() => expect(router.replace).toHaveBeenCalledWith("/tenants"));
    expect(router.refresh).toHaveBeenCalled();
    const [url, init] = fetch.mock.calls[0] as unknown as [string, RequestInit];
    expect(url).toBe("/api/auth/login");
    expect(JSON.parse(String(init.body))).toEqual({ phone: "90 123 45 67", password: "secret" });
  });

  it("network failure is not a crash", async () => {
    vi.stubGlobal(
      "fetch",
      vi.fn(async () => Promise.reject(new TypeError("offline"))),
    );
    renderWithIntl(<LoginForm next="/" />);
    await fill("901234567", "x");
    expect(await screen.findByRole("alert")).toHaveTextContent("Server javob bermadi");
  });
});
