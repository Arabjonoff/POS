import { CalendarClock, MonitorOff, Store, TrendingUp, Wallet } from "lucide-react";
import Link from "next/link";
import { useFormatter, useTranslations } from "next-intl";
import type { ReactNode } from "react";

import { Badge } from "@/components/ui/badge";
import { buttonVariants } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { formatDate, formatMoney } from "@/lib/format";
import type { Stats } from "@/lib/platform";

import { RevenueChart } from "./revenue-chart";

function Kpi({
  label,
  value,
  hint,
  icon,
  testId,
}: {
  label: string;
  value: string;
  hint?: string;
  icon: ReactNode;
  testId: string;
}) {
  return (
    <Card data-testid={testId}>
      <CardContent className="flex flex-col gap-1">
        <div className="text-muted-foreground flex items-center justify-between text-sm">
          {label}
          <span aria-hidden className="text-muted-foreground [&_svg]:size-4">
            {icon}
          </span>
        </div>
        <div className="text-2xl font-semibold tabular-nums">{value}</div>
        {hint && <p className="text-muted-foreground text-xs">{hint}</p>}
      </CardContent>
    </Card>
  );
}

/** Bosh sahifa: `GET /platform/stats/` javobi (spec: admin-dashboard.md, 2-band). */
export function Dashboard({ stats }: { stats: Stats }) {
  const t = useTranslations("home");
  const currency = useTranslations("format")("currency");
  const format = useFormatter();
  const { tenants } = stats;
  const chart = stats.monthly_revenue.map(({ month, revenue_tiyin }) => {
    const [year, m] = month.split("-").map(Number);
    return {
      label: format.dateTime(new Date(Date.UTC(year, m - 1, 1)), {
        month: "short",
        year: "2-digit",
        timeZone: "UTC",
      }),
      revenueTiyin: revenue_tiyin,
    };
  });

  return (
    <div className="mx-auto flex max-w-6xl flex-col gap-6">
      <div>
        <h1 className="text-2xl font-semibold tracking-tight">{t("title")}</h1>
        <p className="text-muted-foreground mt-1 text-sm">{t("subtitle")}</p>
      </div>

      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <Kpi
          testId="kpi-active"
          label={t("activeTenants")}
          value={String(tenants.active)}
          hint={t("tenantStatuses", {
            total: tenants.total,
            grace: tenants.grace,
            readonly: tenants.readonly,
            blocked: tenants.blocked,
          })}
          icon={<Store />}
        />
        <Kpi
          testId="kpi-trial"
          label={t("trialTenants")}
          value={String(tenants.trial)}
          icon={<CalendarClock />}
        />
        <Kpi
          testId="kpi-mrr"
          label={t("mrr")}
          value={formatMoney(stats.mrr_tiyin, currency)}
          hint={t("mrrHint")}
          icon={<TrendingUp />}
        />
        <Kpi
          testId="kpi-revenue"
          label={t("revenueThisMonth")}
          value={formatMoney(stats.revenue_this_month_tiyin, currency)}
          icon={<Wallet />}
        />
      </div>

      <div className="grid gap-4 lg:grid-cols-3">
        <Card className="lg:col-span-2">
          <CardHeader>
            <CardTitle>
              <h2>{t("revenueChart")}</h2>
            </CardTitle>
            <CardDescription>{t("revenueChartHint")}</CardDescription>
          </CardHeader>
          <CardContent>
            <RevenueChart data={chart} currency={currency} />
          </CardContent>
        </Card>

        <div className="flex flex-col gap-4">
          <Card data-testid="expiring">
            <CardHeader>
              <CardTitle>
                <h2>{t("expiringTitle")}</h2>
              </CardTitle>
            </CardHeader>
            <CardContent>
              {stats.expiring_soon.length === 0 ? (
                <p className="text-muted-foreground text-sm">{t("expiringEmpty")}</p>
              ) : (
                <ul className="flex flex-col divide-y">
                  {stats.expiring_soon.map((row) => (
                    <li key={row.tenant} className="flex items-center gap-3 py-3 first:pt-0 last:pb-0">
                      <div className="min-w-0 flex-1">
                        <Link
                          href={`/tenants/${row.tenant}`}
                          className="block truncate font-medium hover:underline"
                        >
                          {row.name}
                        </Link>
                        <p className="text-muted-foreground text-xs">
                          {t("paidUntil", { date: formatDate(row.paid_until) })}
                        </p>
                      </div>
                      <Badge variant={row.days_left <= 2 ? "destructive" : "secondary"}>
                        {t("daysLeft", { days: row.days_left })}
                      </Badge>
                      <Link
                        href={`/tenants/${row.tenant}?payment=1`}
                        className={buttonVariants({ variant: "outline", size: "sm" })}
                      >
                        {t("addPayment")}
                      </Link>
                    </li>
                  ))}
                </ul>
              )}
            </CardContent>
          </Card>

          <Card data-testid="stale-devices">
            <CardContent className="flex items-center gap-3">
              <span
                className={
                  stats.stale_devices > 0
                    ? "bg-destructive/10 text-destructive grid size-10 place-items-center rounded-full"
                    : "bg-muted text-muted-foreground grid size-10 place-items-center rounded-full"
                }
              >
                <MonitorOff className="size-5" aria-hidden />
              </span>
              <div className="min-w-0 flex-1">
                <p className="font-medium">{t("staleTitle", { count: stats.stale_devices })}</p>
                <p className="text-muted-foreground text-xs">{t("staleText")}</p>
              </div>
              {stats.stale_devices > 0 && (
                <Link
                  href="/devices?stale_days=3"
                  className={buttonVariants({ variant: "ghost", size: "sm" })}
                >
                  {t("staleView")}
                </Link>
              )}
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
}
