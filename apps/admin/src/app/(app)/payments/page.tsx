import { CreditCard } from "lucide-react";
import Link from "next/link";
import { getTranslations } from "next-intl/server";

import { PaymentFilters } from "@/components/payments/payment-filters";
import { buttonVariants } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { formatDate, formatDateTime, formatMoney, formatSomPlain } from "@/lib/format";
import { PAGE_SIZE, listPayments } from "@/lib/platform";
import { cn } from "@/lib/utils";

const ISO_DATE = /^\d{4}-\d{2}-\d{2}$/;

function one(value: string | string[] | undefined): string {
  const v = Array.isArray(value) ? value[0] : value;
  return v && ISO_DATE.test(v) ? v : "";
}

export default async function PaymentsPage({ searchParams }: PageProps<"/payments">) {
  const params = await searchParams;
  const dateFrom = one(params.date_from);
  const dateTo = one(params.date_to);
  const page = Math.max(1, Number(Array.isArray(params.page) ? params.page[0] : params.page) || 1);

  const t = await getTranslations("payments");
  const detail = await getTranslations("tenants.detail");
  const currency = (await getTranslations("format"))("currency");
  const data = await listPayments({ dateFrom, dateTo, page });
  const from = data.count === 0 ? 0 : (page - 1) * PAGE_SIZE + 1;
  const to = Math.min(page * PAGE_SIZE, data.count);
  const link = (target: number) => {
    const query = new URLSearchParams();
    if (dateFrom) query.set("date_from", dateFrom);
    if (dateTo) query.set("date_to", dateTo);
    if (target > 1) query.set("page", String(target));
    const text = query.toString();
    return text ? `/payments?${text}` : "/payments";
  };

  const csvRows: (string | number | null)[][] = [
    [detail("paidAt"), t("tenant"), detail("amount"), detail("months"), detail("period"), detail("method"), detail("note")],
    ...data.results.map((p) => [
      p.paid_at ? formatDateTime(p.paid_at) : "",
      p.tenant_name,
      formatSomPlain(p.amount_tiyin),
      p.months,
      `${formatDate(p.period_from)} – ${formatDate(p.period_to)}`,
      detail(`methods.${p.method}`),
      p.note ?? "",
    ]),
  ];

  return (
    <div className="mx-auto flex max-w-6xl flex-col gap-6">
      <div>
        <h1 className="text-2xl font-semibold tracking-tight">{t("title")}</h1>
        <p className="text-muted-foreground mt-1 text-sm">{t("subtitle")}</p>
      </div>

      <PaymentFilters dateFrom={dateFrom} dateTo={dateTo} csvRows={csvRows} />

      {data.results.length === 0 ? (
        <Card>
          <CardContent className="flex flex-col items-center gap-3 py-16 text-center">
            <span className="bg-accent text-accent-foreground grid size-12 place-items-center rounded-full">
              <CreditCard className="size-6" aria-hidden />
            </span>
            <h2 className="text-lg font-semibold">{t("empty")}</h2>
          </CardContent>
        </Card>
      ) : (
        <Card className="py-0">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead className="pl-4">{detail("paidAt")}</TableHead>
                <TableHead>{t("tenant")}</TableHead>
                <TableHead className="text-right">{detail("amount")}</TableHead>
                <TableHead>{detail("months")}</TableHead>
                <TableHead>{detail("period")}</TableHead>
                <TableHead>{detail("method")}</TableHead>
                <TableHead className="pr-4">{detail("note")}</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {data.results.map((p) => (
                <TableRow key={p.id} data-testid="payment-row">
                  <TableCell className="pl-4 tabular-nums">{p.paid_at ? formatDateTime(p.paid_at) : "—"}</TableCell>
                  <TableCell>
                    <Link href={`/tenants/${p.tenant}?tab=payments`} className="font-medium hover:underline">
                      {p.tenant_name}
                    </Link>
                  </TableCell>
                  <TableCell className={cn("text-right tabular-nums", p.amount_tiyin < 0 && "text-destructive")}>
                    {formatMoney(p.amount_tiyin, currency)}
                  </TableCell>
                  <TableCell className="tabular-nums">{p.months}</TableCell>
                  <TableCell className="tabular-nums">
                    {formatDate(p.period_from)} – {formatDate(p.period_to)}
                  </TableCell>
                  <TableCell>{detail(`methods.${p.method}`)}</TableCell>
                  <TableCell className="text-muted-foreground pr-4">{p.note}</TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
          <div className="border-t px-4 py-3 text-right text-sm font-medium tabular-nums" data-testid="payments-total">
            {t("total", { amount: formatMoney(data.total_tiyin, currency) })}
          </div>
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
