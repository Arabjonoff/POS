import { MonitorSmartphone } from "lucide-react";
import Link from "next/link";
import { getTranslations } from "next-intl/server";

import { BlockDialog } from "@/components/tenants/block-dialog";
import { StatusBadge } from "@/components/tenants/status-badge";
import { buttonVariants } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { formatDateTime } from "@/lib/format";
import { PAGE_SIZE, listDevices } from "@/lib/platform";
import { cn } from "@/lib/utils";

const STALE_DAYS = 3;
const FILTERS = ["all", "stale", "blocked"] as const;
type Filter = (typeof FILTERS)[number];

function one(value: string | string[] | undefined): string | undefined {
  return Array.isArray(value) ? value[0] : value;
}

export default async function DevicesPage({ searchParams }: PageProps<"/devices">) {
  const params = await searchParams;
  const filter: Filter = one(params.blocked) === "true" ? "blocked" : one(params.stale_days) ? "stale" : "all";
  const page = Math.max(1, Number(one(params.page)) || 1);

  const t = await getTranslations("devices");
  const detail = await getTranslations("tenants.detail");
  const data = await listDevices({
    staleDays: filter === "stale" ? STALE_DAYS : undefined,
    blocked: filter === "blocked" ? true : undefined,
    page,
  });
  // Server komponent: har so'rovda bir marta hisoblanadi.
  const staleBefore = Date.now() - STALE_DAYS * 24 * 60 * 60 * 1000;
  const href = (f: Filter, p = 1) => {
    const query = new URLSearchParams();
    if (f === "stale") query.set("stale_days", String(STALE_DAYS));
    if (f === "blocked") query.set("blocked", "true");
    if (p > 1) query.set("page", String(p));
    const text = query.toString();
    return text ? `/devices?${text}` : "/devices";
  };
  const from = data.count === 0 ? 0 : (page - 1) * PAGE_SIZE + 1;
  const to = Math.min(page * PAGE_SIZE, data.count);

  return (
    <div className="mx-auto flex max-w-6xl flex-col gap-6">
      <div>
        <h1 className="text-2xl font-semibold tracking-tight">{t("title")}</h1>
        <p className="text-muted-foreground mt-1 text-sm">{t("subtitle", { count: data.count })}</p>
      </div>

      <nav aria-label={t("filters")} className="flex flex-wrap gap-2">
        {FILTERS.map((f) => (
          <Link
            key={f}
            href={href(f)}
            aria-current={f === filter ? "page" : undefined}
            className={buttonVariants({ variant: f === filter ? "default" : "outline", size: "lg" })}
          >
            {t(`filter.${f}`)}
          </Link>
        ))}
      </nav>

      {data.results.length === 0 ? (
        <Card>
          <CardContent className="flex flex-col items-center gap-3 py-16 text-center">
            <span className="bg-accent text-accent-foreground grid size-12 place-items-center rounded-full">
              <MonitorSmartphone className="size-6" aria-hidden />
            </span>
            <h2 className="text-lg font-semibold">{filter === "all" ? t("empty") : t("emptyFiltered")}</h2>
          </CardContent>
        </Card>
      ) : (
        <Card className="py-0">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead className="pl-4">{detail("deviceName")}</TableHead>
                <TableHead>{t("tenant")}</TableHead>
                <TableHead>{detail("platform")}</TableHead>
                <TableHead>{detail("version")}</TableHead>
                <TableHead>{detail("lastSync")}</TableHead>
                <TableHead>{t("status")}</TableHead>
                <TableHead className="pr-4" />
              </TableRow>
            </TableHeader>
            <TableBody>
              {data.results.map((d) => {
                const stale = !d.last_sync_at || new Date(d.last_sync_at).getTime() < staleBefore;
                return (
                  <TableRow key={d.id} data-testid="device-row">
                    <TableCell className="pl-4">
                      <div className="font-medium">{d.name}</div>
                      <div className="text-muted-foreground text-xs">{d.code}</div>
                    </TableCell>
                    <TableCell>
                      <Link href={`/tenants/${d.tenant}?tab=devices`} className="hover:underline">
                        {d.tenant_name}
                      </Link>
                    </TableCell>
                    <TableCell>{detail(`platforms.${d.platform}`)}</TableCell>
                    <TableCell className="tabular-nums">{d.app_version || "—"}</TableCell>
                    <TableCell className={cn("tabular-nums", stale && "text-destructive font-medium")}>
                      {d.last_sync_at ? formatDateTime(d.last_sync_at) : t("neverSynced")}
                    </TableCell>
                    <TableCell>
                      <StatusBadge status={d.is_blocked ? "blocked" : "active"} />
                    </TableCell>
                    <TableCell className="pr-4 text-right">
                      {d.id && <BlockDialog kind="device" targetId={d.id} blocked={Boolean(d.is_blocked)} compact />}
                    </TableCell>
                  </TableRow>
                );
              })}
            </TableBody>
          </Table>
        </Card>
      )}

      {data.count > PAGE_SIZE && (
        <nav aria-label={t("pagination")} className="flex items-center justify-between gap-3 text-sm">
          <span className="text-muted-foreground tabular-nums">{t("pageInfo", { from, to, total: data.count })}</span>
          <div className="flex gap-2">
            {data.previous ? (
              <Link href={href(filter, page - 1)} className={buttonVariants({ variant: "outline", size: "lg" })}>
                {t("prev")}
              </Link>
            ) : null}
            {data.next ? (
              <Link href={href(filter, page + 1)} className={buttonVariants({ variant: "outline", size: "lg" })}>
                {t("next")}
              </Link>
            ) : null}
          </div>
        </nav>
      )}
    </div>
  );
}
