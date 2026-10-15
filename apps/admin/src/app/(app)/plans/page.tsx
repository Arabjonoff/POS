import { Layers } from "lucide-react";
import { getTranslations } from "next-intl/server";

import { DeactivatePlan } from "@/components/plans/deactivate-plan";
import { PlanDialog } from "@/components/plans/plan-dialog";
import { Card, CardContent } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { formatMoney } from "@/lib/format";
import { listAllPlans } from "@/lib/platform";
import { cn } from "@/lib/utils";

export default async function PlansPage() {
  const t = await getTranslations("plans");
  const currency = (await getTranslations("format"))("currency");
  const plans = (await listAllPlans()).sort(
    (a, b) => Number(b.is_active !== false) - Number(a.is_active !== false) || (a.sort ?? 0) - (b.sort ?? 0),
  );

  return (
    <div className="mx-auto flex max-w-6xl flex-col gap-6">
      <div className="flex flex-wrap items-end justify-between gap-3">
        <div>
          <h1 className="text-2xl font-semibold tracking-tight">{t("title")}</h1>
          <p className="text-muted-foreground mt-1 text-sm">{t("subtitle")}</p>
        </div>
        <PlanDialog />
      </div>

      {plans.length === 0 ? (
        <Card>
          <CardContent className="flex flex-col items-center gap-3 py-16 text-center">
            <span className="bg-accent text-accent-foreground grid size-12 place-items-center rounded-full">
              <Layers className="size-6" aria-hidden />
            </span>
            <h2 className="text-lg font-semibold">{t("empty")}</h2>
          </CardContent>
        </Card>
      ) : (
        <Card className="py-0">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead className="pl-4">{t("name")}</TableHead>
                <TableHead className="text-right">{t("pricePerMonth")}</TableHead>
                <TableHead className="text-right">{t("maxDevices")}</TableHead>
                <TableHead className="text-right">{t("maxUsers")}</TableHead>
                <TableHead className="text-right">{t("subscribers")}</TableHead>
                <TableHead>{t("state")}</TableHead>
                <TableHead className="pr-4" />
              </TableRow>
            </TableHeader>
            <TableBody>
              {plans.map((plan) => {
                const active = plan.is_active !== false;
                return (
                  <TableRow key={plan.id} data-testid="plan-row" className={cn(!active && "text-muted-foreground")}>
                    <TableCell className="pl-4 font-medium">{plan.name}</TableCell>
                    <TableCell className="text-right tabular-nums">
                      {formatMoney(plan.price_tiyin_per_month, currency)}
                    </TableCell>
                    <TableCell className="text-right tabular-nums">{plan.max_devices ?? "—"}</TableCell>
                    <TableCell className="text-right tabular-nums">{plan.max_users ?? "—"}</TableCell>
                    <TableCell className="text-right tabular-nums">{plan.subscribers_count}</TableCell>
                    <TableCell>
                      <span
                        className={cn(
                          "inline-flex h-6 items-center rounded-full px-2.5 text-xs font-medium",
                          active ? "bg-chart-2/10 text-chart-2" : "bg-muted text-muted-foreground",
                        )}
                      >
                        {active ? t("active") : t("inactive")}
                      </span>
                    </TableCell>
                    <TableCell className="pr-4 text-right whitespace-nowrap">
                      {plan.id && (
                        <>
                          <PlanDialog
                            plan={{
                              id: plan.id,
                              name: plan.name,
                              priceTiyin: plan.price_tiyin_per_month,
                              maxDevices: plan.max_devices ?? 1,
                              maxUsers: plan.max_users ?? 1,
                              isActive: active,
                            }}
                          />
                          {active && (
                            <DeactivatePlan id={plan.id} name={plan.name} subscribers={plan.subscribers_count} />
                          )}
                        </>
                      )}
                    </TableCell>
                  </TableRow>
                );
              })}
            </TableBody>
          </Table>
        </Card>
      )}
    </div>
  );
}
