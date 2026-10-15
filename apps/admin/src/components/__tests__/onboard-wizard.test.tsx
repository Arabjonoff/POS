import { screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { beforeEach, describe, expect, it, vi } from "vitest";

import { renderWithIntl } from "@/test-utils";

import { OnboardWizard, validateStep } from "../tenants/onboard-wizard";

const actions = vi.hoisted(() => ({ onboardTenant: vi.fn() }));
vi.mock("@/app/(app)/tenants/actions", () => actions);

const plans = [
  { id: "p1", name: "Start", priceTiyin: 9_900_000 },
  { id: "p2", name: "Biznes", priceTiyin: 19_900_000 },
];

const base = {
  name: "Baraka",
  address: "",
  notes: "",
  ownerPhone: "90 123 45 67",
  ownerName: "Ali",
  ownerPassword: "",
  plan: "p1",
  trialDays: 14,
};

beforeEach(() => vi.clearAllMocks());

describe("validateStep", () => {
  it("checks each step's own fields", () => {
    expect(validateStep(1, { ...base, name: " " }, false)).toEqual(["name"]);
    expect(validateStep(2, { ...base, ownerPhone: "90 12", ownerName: "" }, false)).toEqual([
      "phone",
      "ownerName",
    ]);
    expect(validateStep(2, { ...base, ownerPassword: "short" }, true)).toEqual(["password"]);
    expect(validateStep(2, { ...base, ownerPassword: "short" }, false)).toEqual([]);
    expect(validateStep(3, { ...base, plan: "", trialDays: 91 }, false)).toEqual(["plan", "trialDays"]);
    expect(validateStep(3, { ...base, trialDays: 0 }, false)).toEqual([]);
  });
});

async function walkToPlanStep() {
  const user = userEvent.setup();
  await user.type(screen.getByLabelText("Do'kon nomi"), "Baraka");
  await user.click(screen.getByRole("button", { name: "Davom etish" }));
  await user.type(screen.getByLabelText("Ega telefoni"), "90 123 45 67");
  await user.type(screen.getByLabelText("Ega ismi"), "Ali");
  await user.click(screen.getByRole("button", { name: "Davom etish" }));
  return user;
}

describe("OnboardWizard", () => {
  it("creates a tenant with a generated password and shows the credentials", async () => {
    actions.onboardTenant.mockResolvedValue({
      ok: true,
      data: {
        tenantId: "t1",
        tenantName: "Baraka",
        ownerPhone: "+998901234567",
        ownerName: "Ali",
        temporaryPassword: "Xy7-pass99",
      },
    });
    renderWithIntl(<OnboardWizard plans={plans} />);
    const user = await walkToPlanStep();
    expect(screen.getByRole("radio", { name: /^Start/ })).toBeChecked();
    await user.click(screen.getByRole("radio", { name: /^Biznes/ }));
    await user.click(screen.getByRole("button", { name: "Mijozni yaratish" }));

    expect(actions.onboardTenant).toHaveBeenCalledWith({
      ...base,
      plan: "p2",
    });
    expect(await screen.findByTestId("temporary-password")).toHaveTextContent("Xy7-pass99");
    expect(screen.getByRole("link", { name: "Mijoz sahifasi" })).toHaveAttribute("href", "/tenants/t1");
  });

  it("a taken phone sends the admin back to the owner step", async () => {
    actions.onboardTenant.mockResolvedValue({ ok: false, error: "phone_taken" });
    renderWithIntl(<OnboardWizard plans={plans} />);
    const user = await walkToPlanStep();
    await user.click(screen.getByRole("button", { name: "Mijozni yaratish" }));
    expect(await screen.findByText("Bu telefon allaqachon ro'yxatdan o'tgan")).toBeInTheDocument();
    expect(screen.getByLabelText("Ega telefoni")).toHaveValue("90 123 45 67");
  });

  it("a manual password must be at least 8 characters and is sent as is", async () => {
    actions.onboardTenant.mockResolvedValue({ ok: false, error: "unavailable" });
    renderWithIntl(<OnboardWizard plans={plans} />);
    const user = userEvent.setup();
    await user.type(screen.getByLabelText("Do'kon nomi"), "Baraka");
    await user.click(screen.getByRole("button", { name: "Davom etish" }));
    await user.type(screen.getByLabelText("Ega telefoni"), "901234567");
    await user.type(screen.getByLabelText("Ega ismi"), "Ali");
    await user.click(screen.getByRole("radio", { name: "Parolni o'zim kiritaman" }));
    await user.type(screen.getByLabelText("Parol (kamida 8 belgi)"), "1234");
    await user.click(screen.getByRole("button", { name: "Davom etish" }));
    expect(screen.getByText("Parol kamida 8 belgidan iborat bo'lsin")).toBeInTheDocument();
    await user.type(screen.getByLabelText("Parol (kamida 8 belgi)"), "5678");
    await user.click(screen.getByRole("button", { name: "Davom etish" }));
    await user.click(screen.getByRole("button", { name: "Mijozni yaratish" }));
    expect(actions.onboardTenant).toHaveBeenCalledWith(
      expect.objectContaining({ ownerPhone: "901234567", ownerPassword: "12345678" }),
    );
    expect(await screen.findByRole("alert")).toHaveTextContent("Server javob bermadi");
  });
});
