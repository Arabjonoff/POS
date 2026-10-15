import { ArrowLeft, TriangleAlert } from "lucide-react";
import Link from "next/link";
import { getTranslations } from "next-intl/server";
import type { ReactNode } from "react";

import { BlockDialog } from "@/components/tenants/block-dialog";
import { ResetPassword } from "@/components/tenants/reset-password";
import { StatusBadge } from "@/components/tenants/status-badge";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { formatDate, formatDateTime, formatMoney } from "@/lib/format";
import {
  getTenant,
  tenantDevices,
  tenantPayments,
  tenantSyncEvents,
  tenantUsers,
} from "@/lib/platform";
import { cn } from "@/lib/utils";

const TABS = ["overview", "payments", "devices", "users", "activity"] as const;
type Tab = (typeof TABS)[number];

function Empty({ children }: { children: ReactNode }) {
  return <p className="text-muted-foreground py-8 text-center text-sm">{children}</p>;
}

function Row({ label, children }: { label: string; children: ReactNode }) {
  return (
    <>
      <dt className="text-muted-foreground">{label}</dt>
      <dd className="font-medium">{children}</dd>
    </>
  );
}

export default async function TenantPage({ params, searchParams }: PageProps<"/tenants/[id]">) {
  const { id } = await params;
  const query = await searchParams;
  const tab: Tab = TABS.includes(query.tab as Tab) ? (query.tab as Tab) : "overview";

  const t = await getTranslations("tenants.detail");
  const common = await getTranslations("tenants");
  const currency = (await getTranslations("format"))("currency");
  const tenant = await getTenant(id);
  const dateTime = (value: string | null | undefined) => (value ? formatDateTime(value) : common("never"));
  const sub = tenant.subscription;

  let body: ReactNode;
  if (tab === "overview") {
    body = (
      <div className="grid gap-4 lg:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle>
              <h2>{t("subscription")}</h2>
            </CardTitle>
          </CardHeader>
          <CardContent>
            <dl className="grid grid-cols-[auto_1fr] gap-x-6 gap-y-2 text-sm">
              <Row label={common("columns.status")}>
                <StatusBadge status={tenant.status} />
              </Row>
              <Row label={common("columns.plan")}>{tenant.plan ?? "—"}</Row>
              <Row label={t("trialEndsAt")}>{tenant.trial_ends_at ? formatDate(tenant.trial_ends_at) : "—"}</Row>
              <Row label={t("paidUntil")}>{tenant.paid_until ? formatDate(tenant.paid_until) : "—"}</Row>
              <Row label={t("daysLeft")}>{sub?.days_left ?? "—"}</Row>
              <Row label={t("graceDays")}>{sub?.grace_days ?? "—"}</Row>
              <Row label={t("offlineDays")}>{sub?.offline_days ?? "—"}</Row>
            </dl>
          </CardContent>
        </Card>
        <Card>
          <CardHeader>
            <CardTitle>
              <h2>{t("store")}</h2>
            </CardTitle>
          </CardHeader>
          <CardContent>
            <dl className="grid grid-cols-[auto_1fr] gap-x-6 gap-y-2 text-sm">
              <Row label={common("columns.owner")}>
                <div>{tenant.owner_name}</div>
                <div className="text-muted-foreground font-normal tabular-nums">{tenant.owner_phone}</div>
              </Row>
              <Row label={t("address")}>{tenant.address || "—"}</Row>
              <Row label={t("timezone")}>{tenant.timezone ?? "—"}</Row>
              <Row label={t("users")}>{tenant.users_count}</Row>
              <Row label={common("columns.devices")}>{tenant.devices_count}</Row>
              <Row label={common("columns.lastActivity")}>{dateTime(tenant.last_activity_at)}</Row>
              <Row label={t("createdAt")}>{dateTime(tenant.created_at)}</Row>
              {tenant.notes ? <Row label={t("notes")}>{tenant.notes}</Row> : null}
            </dl>
          </CardContent>
        </Card>
      </div>
    );
  } else if (tab === "payments") {
    const payments = await tenantPayments(id);
    body =
      payments.results.length === 0 ? (
        <Empty>{t("noPayments")}</Empty>
      ) : (
        <Card className="py-0">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead className="pl-4">{t("paidAt")}</TableHead>
                <TableHead className="text-right">{t("amount")}</TableHead>
                <TableHead>{t("months")}</TableHead>
                <TableHead>{t("period")}</TableHead>
                <TableHead>{t("method")}</TableHead>
                <TableHead className="pr-4">{t("note")}</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {payments.results.map((p) => (
                <TableRow key={p.id} data-testid="payment-row">
                  <TableCell className="pl-4 tabular-nums">{dateTime(p.paid_at)}</TableCell>
                  <TableCell className={cn("text-right tabular-nums", p.amount_tiyin < 0 && "text-destructive")}>
                    {formatMoney(p.amount_tiyin, currency)}
                  </TableCell>
                  <TableCell className="tabular-nums">{p.months}</TableCell>
                  <TableCell className="tabular-nums">
                    {formatDate(p.period_from)} – {formatDate(p.period_to)}
                  </TableCell>
                  <TableCell>{t(`methods.${p.method}`)}</TableCell>
                  <TableCell className="text-muted-foreground pr-4">{p.note}</TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
          <div className="border-t px-4 py-3 text-right text-sm font-medium tabular-nums">
            {t("total", { amount: formatMoney(payments.total_tiyin ?? 0, currency) })}
          </div>
        </Card>
      );
  } else if (tab === "devices") {
    const devices = await tenantDevices(id);
    body =
      devices.length === 0 ? (
        <Empty>{t("noDevices")}</Empty>
      ) : (
        <Card className="py-0">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead className="pl-4">{t("deviceName")}</TableHead>
                <TableHead>{t("platform")}</TableHead>
                <TableHead>{t("version")}</TableHead>
                <TableHead>{t("lastSync")}</TableHead>
                <TableHead className="pr-4">{common("columns.status")}</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {devices.map((d) => (
                <TableRow key={d.id} data-testid="device-row">
                  <TableCell className="pl-4">
                    <div className="font-medium">{d.name}</div>
                    <div className="text-muted-foreground text-xs">{d.code}</div>
                  </TableCell>
                  <TableCell>{t(`platforms.${d.platform}`)}</TableCell>
                  <TableCell className="tabular-nums">{d.app_version || "—"}</TableCell>
                  <TableCell className="tabular-nums">{dateTime(d.last_sync_at)}</TableCell>
                  <TableCell className="pr-4">
                    {d.is_blocked ? <StatusBadge status="blocked" /> : <StatusBadge status="active" />}
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </Card>
      );
  } else if (tab === "users") {
    const users = await tenantUsers(id);
    body =
      users.length === 0 ? (
        <Empty>{t("noUsers")}</Empty>
      ) : (
        <Card className="py-0">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead className="pl-4">{t("userName")}</TableHead>
                <TableHead>{t("role")}</TableHead>
                <TableHead>{t("lastLogin")}</TableHead>
                <TableHead className="pr-4" />
              </TableRow>
            </TableHeader>
            <TableBody>
              {users.map((u) => (
                <TableRow key={u.id} data-testid="user-row">
                  <TableCell className="pl-4">
                    <div className={cn("font-medium", u.is_active === false && "text-muted-foreground line-through")}>
                      {u.full_name}
                    </div>
                    <div className="text-muted-foreground text-xs tabular-nums">{u.phone ?? ""}</div>
                  </TableCell>
                  <TableCell>{t(`roles.${u.role}`)}</TableCell>
                  <TableCell className="tabular-nums">{dateTime(u.last_login)}</TableCell>
                  <TableCell className="pr-4 text-right">
                    {u.id && (u.role === "owner" || u.role === "manager") ? (
                      <ResetPassword userId={u.id} userName={u.full_name} />
                    ) : null}
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </Card>
      );
  } else {
    const events = await tenantSyncEvents(id);
    body =
      events.length === 0 ? (
        <Empty>{t("noEvents")}</Empty>
      ) : (
        <Card className="py-0">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead className="pl-4">{t("eventType")}</TableHead>
                <TableHead>{common("columns.status")}</TableHead>
                <TableHead>{t("attempts")}</TableHead>
                <TableHead className="pr-4">{t("receivedAt")}</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {events.map((e) => (
                <TableRow key={e.id} data-testid="event-row">
                  <TableCell className="pl-4 font-mono text-xs">{e.type}</TableCell>
                  <TableCell>
                    <span className={cn("text-xs font-medium", e.status === "rejected" && "text-destructive")}>
                      {t(`eventStatus.${e.status}`)}
                    </span>
                  </TableCell>
                  <TableCell className="tabular-nums">{e.attempts ?? 0}</TableCell>
                  <TableCell className="pr-4 tabular-nums">{dateTime(e.received_at)}</TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </Card>
      );
  }

  return (
    <div className="mx-auto flex max-w-6xl flex-col gap-6">
      <Link href="/tenants" className="text-muted-foreground hover:text-foreground flex w-fit items-center gap-1 text-sm">
        <ArrowLeft className="size-4" aria-hidden />
        {common("title")}
      </Link>
      <div className="flex flex-wrap items-start justify-between gap-3">
        <div>
          <div className="flex flex-wrap items-center gap-3">
            <h1 className="text-2xl font-semibold tracking-tight">{tenant.name}</h1>
            <StatusBadge status={tenant.status} />
          </div>
          <p className="text-muted-foreground mt-1 text-sm tabular-nums">
            {tenant.owner_name} · {tenant.owner_phone}
          </p>
        </div>
        {tenant.id && <BlockDialog tenantId={tenant.id} blocked={Boolean(tenant.is_blocked)} />}
      </div>

      {tenant.is_blocked && (
        <div role="status" className="bg-destructive/10 text-destructive flex items-start gap-2 rounded-lg p-3 text-sm">
          <TriangleAlert className="mt-0.5 size-4 shrink-0" aria-hidden />
          <span>{t("blockedBanner", { reason: tenant.blocked_reason || "—" })}</span>
        </div>
      )}

      <nav aria-label={t("tabs")} className="flex gap-1 overflow-x-auto border-b">
        {TABS.map((name) => (
          <Link
            key={name}
            href={name === "overview" ? `/tenants/${id}` : `/tenants/${id}?tab=${name}`}
            aria-current={name === tab ? "page" : undefined}
            className={cn(
              "-mb-px flex h-11 items-center border-b-2 px-3 text-sm font-medium whitespace-nowrap transition-colors",
              name === tab
                ? "border-primary text-foreground"
                : "text-muted-foreground hover:text-foreground border-transparent",
            )}
          >
            {t(`tab.${name}`)}
          </Link>
        ))}
      </nav>

      {body}
    </div>
  );
}
