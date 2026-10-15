import { Store } from "lucide-react";
import Link from "next/link";
import { useTranslations } from "next-intl";

import { Card, CardContent } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { formatDate, formatDateTime } from "@/lib/format";
import type { TenantRow } from "@/lib/platform";

import { StatusBadge } from "./status-badge";

/** To'langan (yoki sinov) muddati: obunaning oxirgi kuni. */
export function coveredUntil(row: Pick<TenantRow, "status" | "paid_until" | "trial_ends_at">): string | null {
  if (row.status === "trial" && row.trial_ends_at) return row.trial_ends_at;
  return row.paid_until ?? row.trial_ends_at;
}

export function TenantsTable({ rows, filtered }: { rows: TenantRow[]; filtered: boolean }) {
  const t = useTranslations("tenants");

  if (rows.length === 0) {
    return (
      <Card>
        <CardContent className="flex flex-col items-center gap-3 py-16 text-center">
          <span className="bg-accent text-accent-foreground grid size-12 place-items-center rounded-full">
            <Store className="size-6" aria-hidden />
          </span>
          <h2 className="text-lg font-semibold">{filtered ? t("emptyFiltered") : t("empty")}</h2>
          {!filtered && <p className="text-muted-foreground max-w-md text-sm">{t("emptyText")}</p>}
        </CardContent>
      </Card>
    );
  }

  return (
    <Card className="py-0">
      <Table>
        <TableHeader>
          <TableRow>
            <TableHead className="pl-4">{t("columns.name")}</TableHead>
            <TableHead>{t("columns.owner")}</TableHead>
            <TableHead>{t("columns.plan")}</TableHead>
            <TableHead>{t("columns.status")}</TableHead>
            <TableHead>{t("columns.paidUntil")}</TableHead>
            <TableHead className="text-right">{t("columns.devices")}</TableHead>
            <TableHead className="pr-4">{t("columns.lastActivity")}</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {rows.map((row) => {
            const until = coveredUntil(row);
            return (
              <TableRow key={row.id} data-testid="tenant-row">
                <TableCell className="pl-4">
                  <Link href={`/tenants/${row.id}`} className="font-medium hover:underline">
                    {row.name}
                  </Link>
                </TableCell>
                <TableCell>
                  <div>{row.owner_name}</div>
                  <div className="text-muted-foreground text-xs tabular-nums">{row.owner_phone}</div>
                </TableCell>
                <TableCell>{row.plan ?? "—"}</TableCell>
                <TableCell>
                  <StatusBadge status={row.status} />
                </TableCell>
                <TableCell className="tabular-nums">{until ? formatDate(until) : "—"}</TableCell>
                <TableCell className="text-right tabular-nums">{row.devices_count}</TableCell>
                <TableCell className="text-muted-foreground pr-4 tabular-nums">
                  {row.last_activity_at ? formatDateTime(row.last_activity_at) : t("never")}
                </TableCell>
              </TableRow>
            );
          })}
        </TableBody>
      </Table>
    </Card>
  );
}
