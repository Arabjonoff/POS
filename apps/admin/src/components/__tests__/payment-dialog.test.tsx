import { screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

import { renderWithIntl } from "@/test-utils";

import { PaymentDialog } from "../tenants/payment-dialog";

const actions = vi.hoisted(() => ({ recordPayment: vi.fn() }));
vi.mock("@/app/(app)/tenants/actions", () => actions);

const router = vi.hoisted(() => ({ replace: vi.fn(), refresh: vi.fn(), push: vi.fn() }));
vi.mock("next/navigation", () => ({ useRouter: () => router, usePathname: () => "/tenants/t1" }));

beforeEach(() => {
  vi.clearAllMocks();
  // 15.10.2026 12:00 Toshkent.
  vi.useFakeTimers({ now: new Date("2026-10-15T07:00:00Z"), toFake: ["Date"] });
});
afterEach(() => vi.useRealTimers());

function open(props: Partial<Parameters<typeof PaymentDialog>[0]> = {}) {
  renderWithIntl(
    <PaymentDialog
      tenantId="t1"
      tenantName="Baraka"
      planPriceTiyin={9_900_000}
      paidUntil="2026-11-30"
      trialEndsAt="2026-09-15"
      defaultOpen
      {...props}
    />,
  );
}

describe("PaymentDialog", () => {
  it("suggests plan price × months and previews the new period", async () => {
    open();
    const user = userEvent.setup();
    expect(screen.getByLabelText("Summa (so'm)")).toHaveValue("99 000");
    expect(screen.getByTestId("payment-preview")).toHaveTextContent("Yangi davr: 30.11.2026 – 30.12.2026");

    await user.click(screen.getByRole("button", { name: "3" }));
    expect(screen.getByLabelText("Summa (so'm)")).toHaveValue("297 000");
    expect(screen.getByTestId("payment-preview")).toHaveTextContent("30.11.2026 – 28.02.2027");
  });

  it("a typed amount is kept when months change; sends whole tiyin", async () => {
    actions.recordPayment.mockResolvedValue({ ok: true, data: { periodFrom: "", periodTo: "" } });
    open({ paidUntil: null, trialEndsAt: "2026-10-01" });
    const user = userEvent.setup();
    const amount = screen.getByLabelText("Summa (so'm)");
    await user.clear(amount);
    await user.type(amount, "250 000,50");
    await user.click(screen.getByRole("button", { name: "6" }));
    expect(amount).toHaveValue("250 000,50");
    // Sinov tugagan, to'lov yo'q → bugundan.
    expect(screen.getByTestId("payment-preview")).toHaveTextContent("15.10.2026 – 15.04.2027");
    await user.click(screen.getByText("Karta"));
    await user.click(screen.getByRole("button", { name: "To'lovni saqlash" }));
    expect(actions.recordPayment).toHaveBeenCalledWith("t1", {
      amountTiyin: 25_000_050,
      months: 6,
      method: "card",
      note: "",
    });
    expect(router.replace).toHaveBeenCalledWith("/tenants/t1?tab=payments");
  });

  it("rejects a bad amount or month count without calling the server", async () => {
    open();
    const user = userEvent.setup();
    await user.clear(screen.getByLabelText("Summa (so'm)"));
    await user.type(screen.getByLabelText("Summa (so'm)"), "abc");
    await user.click(screen.getByRole("button", { name: "To'lovni saqlash" }));
    expect(screen.getByText("Summani so'mda to'g'ri kiriting")).toBeInTheDocument();
    await user.clear(screen.getByLabelText("Oylar soni"));
    await user.type(screen.getByLabelText("Oylar soni"), "40");
    await user.click(screen.getByRole("button", { name: "To'lovni saqlash" }));
    expect(screen.getByText("1 dan 36 gacha butun son")).toBeInTheDocument();
    expect(actions.recordPayment).not.toHaveBeenCalled();
  });
});
