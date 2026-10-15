import { screen, within } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";

import { renderWithIntl } from "@/test-utils";
import type { Stats } from "@/lib/platform";

import { Dashboard } from "../dashboard/dashboard";

vi.mock("../dashboard/revenue-chart", () => ({
  RevenueChart: ({ data }: { data: { label: string; revenueTiyin: number }[] }) => (
    <ol data-testid="revenue-chart">
      {data.map((d) => (
        <li key={d.label}>{`${d.label}=${d.revenueTiyin}`}</li>
      ))}
    </ol>
  ),
}));

function stats(overrides: Partial<Stats> = {}): Stats {
  return {
    tenants: { total: 12, trial: 3, active: 7, grace: 1, readonly: 1, blocked: 0 },
    mrr_tiyin: 135_000_000,
    revenue_this_month_tiyin: 45_000_050,
    expiring_soon: [
      { tenant: "t1", name: "Baraka do'koni", paid_until: "2026-10-16", days_left: 1 },
      { tenant: "t2", name: "Oila market", paid_until: "2026-10-20", days_left: 5 },
    ],
    stale_devices: 2,
    monthly_revenue: [
      { month: "2026-09", revenue_tiyin: 30_000_000 },
      { month: "2026-10", revenue_tiyin: 45_000_050 },
    ],
    ...overrides,
  };
}

describe("Dashboard", () => {
  // toHaveTextContent bo'sh joylarni (NBSP ham) bitta probelga keltiradi.
  it("shows KPI cards with money in so'm", () => {
    renderWithIntl(<Dashboard stats={stats()} />);
    expect(screen.getByRole("heading", { level: 1, name: "Bosh sahifa" })).toBeInTheDocument();
    const active = screen.getByTestId("kpi-active");
    expect(within(active).getByText("7")).toBeInTheDocument();
    expect(active).toHaveTextContent("Jami 12 · muddati o'tgan 1 · faqat o'qish 1 · bloklangan 0");
    expect(within(screen.getByTestId("kpi-trial")).getByText("3")).toBeInTheDocument();
    expect(screen.getByTestId("kpi-mrr")).toHaveTextContent("1 350 000 so'm");
    expect(screen.getByTestId("kpi-revenue")).toHaveTextContent("450 000,50 so'm");
  });

  it("lists subscriptions expiring within 7 days with a payment shortcut", () => {
    renderWithIntl(<Dashboard stats={stats()} />);
    const list = screen.getByTestId("expiring");
    const items = within(list).getAllByRole("listitem");
    expect(items).toHaveLength(2);
    expect(items[0]).toHaveTextContent("Baraka do'koni");
    expect(items[0]).toHaveTextContent("16.10.2026 gacha to'langan");
    expect(items[0]).toHaveTextContent("1 kun");
    expect(within(items[0]).getByRole("link", { name: "To'lov kiritish" })).toHaveAttribute(
      "href",
      "/tenants/t1?payment=1",
    );
  });

  it("monthly revenue goes to the chart with month labels", () => {
    renderWithIntl(<Dashboard stats={stats()} />);
    const bars = within(screen.getByTestId("revenue-chart")).getAllByRole("listitem");
    expect(bars.map((b) => b.textContent)).toEqual([
      expect.stringMatching(/=30000000$/),
      expect.stringMatching(/=45000050$/),
    ]);
  });

  it("stale devices link; empty states", () => {
    renderWithIntl(<Dashboard stats={stats()} />);
    const stale = screen.getByTestId("stale-devices");
    expect(stale).toHaveTextContent("2 ta qurilma sinxronlanmagan");
    expect(within(stale).getByRole("link", { name: "Ko'rish" })).toHaveAttribute(
      "href",
      "/devices?stale_days=3",
    );

    renderWithIntl(<Dashboard stats={stats({ expiring_soon: [], stale_devices: 0 })} />, "ru");
    expect(screen.getByText("Нет подписок, истекающих в течение 7 дней")).toBeInTheDocument();
    expect(screen.getByText("Все устройства синхронизированы")).toBeInTheDocument();
  });
});
