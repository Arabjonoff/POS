import { ScrollText } from "lucide-react";
import Link from "next/link";
import { getTranslations } from "next-intl/server";

import { AuditFilters } from "@/components/audit/audit-filters";
import { buttonVariants } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { AUDIT_ACTIONS, AUDIT_TARGETS, auditChanges } from "@/lib/audit";
import { formatDateTime } from "@/lib/format";
import { PAGE_SIZE, listAuditLog } from "@/lib/platform";

function one(value: string | string[] | undefined): string {
  return (Array.isArray(value) ? value[0] : value) ?? "";
}

export default async function AuditPage({ searchParams }: PageProps<"/audit">) {
  const params = await searchParams;
  const actionParam = one(params.action);
  const targetParam = one(params.target_type);
  const action = (AUDIT_ACTIONS as readonly string[]).includes(actionParam) ? actionParam : "";
  const targetType = (AUDIT_TARGETS as readonly string[]).includes(targetParam) ? targetParam : "";
  const tenant = /^[0-9a-f-]{36}$/i.test(one(params.tenant)) ? one(params.tenant) : "";
  const page = Math.max(1, Number(one(params.page)) || 1);

  const t = await getTranslations("audit");
  const data = await listAuditLog({ action, targetType, tenant, page });
  const from = data.count === 0 ? 0 : (page - 1) * PAGE_SIZE + 1;
  const to = Math.min(page * PAGE_SIZE, data.count);
  const label = (key: string, group: "actions" | "targets", raw: string) =>
    t.has(`${group}.${key}`) ? t(`${group}.${key}`) : raw;
  const link = (target: number) => {
    const query = new URLSearchParams();
    if (action) query.set("action", action);
    if (targetType) query.set("target_type", targetType);
    if (tenant) query.set("tenant", tenant);
    if (target > 1) query.set("page", String(target));
    const text = query.toString();
    return text ? `/audit?${text}` : "/audit";
  };

  return (
    <div className="mx-auto flex max-w-6xl flex-col gap-6">
      <div>
        <h1 className="text-2xl font-semibold tracking-tight">{t("title")}</h1>
        <p className="text-muted-foreground mt-1 text-sm">{t("subtitle")}</p>
      </div>

      <AuditFilters action={action} targetType={targetType} />

      {data.results.length === 0 ? (
        <Card>
          <CardContent className="flex flex-col items-center gap-3 py-16 text-center">
            <span className="bg-accent text-accent-foreground grid size-12 place-items-center rounded-full">
              <ScrollText className="size-6" aria-hidden />
            </span>
            <h2 className="text-lg font-semibold">{t("empty")}</h2>
          </CardContent>
        </Card>
      ) : (
        <Card className="py-0">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead className="pl-4">{t("at")}</TableHead>
                <TableHead>{t("actor")}</TableHead>
                <TableHead>{t("action")}</TableHead>
                <TableHead>{t("target")}</TableHead>
                <TableHead className="pr-4">{t("details")}</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {data.results.map((entry) => {
                const changes = auditChanges(entry.before, entry.after);
                return (
                  <TableRow key={entry.id} data-testid="audit-row" className="align-top">
                    <TableCell className="pl-4 tabular-nums">{entry.at ? formatDateTime(entry.at) : "—"}</TableCell>
                    <TableCell>{entry.actor_name}</TableCell>
                    <TableCell className="font-medium">
                      {label(entry.action.replace(".", "_"), "actions", entry.action)}
                    </TableCell>
                    <TableCell>
                      <div>{label(entry.target_type, "targets", entry.target_type)}</div>
                      {entry.tenant ? (
                        <Link href={`/tenants/${entry.tenant}`} className="text-primary text-xs hover:underline">
                          {t("openTenant")}
                        </Link>
                      ) : null}
                    </TableCell>
                    <TableCell className="max-w-md pr-4 whitespace-normal">
                      {entry.reason ? (
                        <p className="text-sm">
                          <span className="text-muted-foreground">{t("reason")}: </span>
                          {entry.reason}
                        </p>
                      ) : null}
                      {changes.length > 0 && (
                        <details className="text-xs">
                          <summary className="text-muted-foreground cursor-pointer select-none">
                            {t("changes", { count: changes.length })}
                          </summary>
                          <dl className="mt-1 grid grid-cols-[auto_1fr] gap-x-3 gap-y-0.5 font-mono">
                            {changes.map((c) => (
                              <div key={c.field} className="contents">
                                <dt className="text-muted-foreground">{c.field}</dt>
                                <dd className="break-all">
                                  {c.before ? <span className="text-destructive line-through">{c.before}</span> : null}
                                  {c.before ? " → " : ""}
                                  <span>{c.after}</span>
                                </dd>
                              </div>
                            ))}
                          </dl>
                        </details>
                      )}
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
              <Link href={link(page - 1)} className={buttonVariants({ variant: "outline", size: "lg" })}>
                {t("prev")}
              </Link>
            ) : null}
            {data.next ? (
              <Link href={link(page + 1)} className={buttonVariants({ variant: "outline", size: "lg" })}>
                {t("next")}
              </Link>
            ) : null}
          </div>
        </nav>
      )}
    </div>
  );
}
