import { Plus } from "lucide-react";
import Link from "next/link";
import { getTranslations } from "next-intl/server";

import { TenantFilters } from "@/components/tenants/tenant-filters";
import { TenantsTable, coveredUntil } from "@/components/tenants/tenants-table";
import { buttonVariants } from "@/components/ui/button";
import { PAGE_SIZE, TENANT_STATUSES, listTenants, type TenantStatus } from "@/lib/platform";

function one(value: string | string[] | undefined): string | undefined {
  return Array.isArray(value) ? value[0] : value;
}

export default async function TenantsPage({ searchParams }: PageProps<"/tenants">) {
  const params = await searchParams;
  const search = one(params.search)?.trim() ?? "";
  const statusParam = one(params.status);
  const status = TENANT_STATUSES.includes(statusParam as TenantStatus)
    ? (statusParam as TenantStatus)
    : undefined;
  const page = Math.max(1, Number(one(params.page)) || 1);

  const t = await getTranslations("tenants");
  const data = await listTenants({ search, status, page });
  const from = data.count === 0 ? 0 : (page - 1) * PAGE_SIZE + 1;
  const to = Math.min(page * PAGE_SIZE, data.count);

  const link = (target: number) => {
    const query = new URLSearchParams();
    if (search) query.set("search", search);
    if (status) query.set("status", status);
    if (target > 1) query.set("page", String(target));
    const text = query.toString();
    return text ? `/tenants?${text}` : "/tenants";
  };

  const csvRows: (string | number | null)[][] = [
    [
      t("columns.name"),
      t("columns.owner"),
      t("columns.phone"),
      t("columns.plan"),
      t("columns.status"),
      t("columns.paidUntil"),
      t("columns.devices"),
      t("columns.lastActivity"),
    ],
    ...data.results.map((row) => [
      row.name,
      row.owner_name,
      row.owner_phone,
      row.plan,
      t(`status.${row.status as TenantStatus}`),
      coveredUntil(row),
      row.devices_count,
      row.last_activity_at,
    ]),
  ];

  return (
    <div className="mx-auto flex max-w-6xl flex-col gap-6">
      <div className="flex flex-wrap items-end justify-between gap-3">
        <div>
          <h1 className="text-2xl font-semibold tracking-tight">{t("title")}</h1>
          <p className="text-muted-foreground mt-1 text-sm">{t("subtitle", { count: data.count })}</p>
        </div>
        <Link href="/tenants/new" className={buttonVariants({ size: "lg" })}>
          <Plus aria-hidden />
          {t("add")}
        </Link>
      </div>

      <TenantFilters csvRows={csvRows} />
      <TenantsTable rows={data.results} filtered={Boolean(search || status)} />

      {data.count > PAGE_SIZE && (
        <nav aria-label={t("pagination")} className="flex items-center justify-between gap-3 text-sm">
          <span className="text-muted-foreground tabular-nums">
            {t("pageInfo", { from, to, total: data.count })}
          </span>
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
