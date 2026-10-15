"use client";

import { Download } from "lucide-react";
import { usePathname, useRouter } from "next/navigation";
import { useTranslations } from "next-intl";
import { useState, useTransition, type FormEvent } from "react";

import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { downloadCsv, toCsv } from "@/lib/csv";

/** Sana oralig'i (`?date_from=&date_to=`, `paid_at` Toshkent bo'yicha) va CSV. */
export function PaymentFilters({
  dateFrom,
  dateTo,
  csvRows,
}: {
  dateFrom: string;
  dateTo: string;
  csvRows: (string | number | null)[][];
}) {
  const t = useTranslations("payments");
  const router = useRouter();
  const pathname = usePathname();
  const [from, setFrom] = useState(dateFrom);
  const [to, setTo] = useState(dateTo);
  const [pending, startTransition] = useTransition();

  function go(nextFrom: string, nextTo: string) {
    const query = new URLSearchParams();
    if (nextFrom) query.set("date_from", nextFrom);
    if (nextTo) query.set("date_to", nextTo);
    const text = query.toString();
    startTransition(() => router.replace(text ? `${pathname}?${text}` : pathname));
  }

  function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    go(from, to);
  }

  return (
    <form
      onSubmit={submit}
      aria-label={t("filters")}
      aria-busy={pending}
      className="flex flex-wrap items-end gap-2"
    >
      <div className="flex flex-col gap-1.5">
        <Label htmlFor="date-from">{t("from")}</Label>
        <Input id="date-from" type="date" value={from} onChange={(e) => setFrom(e.target.value)} className="h-9 dark:[color-scheme:dark]" />
      </div>
      <div className="flex flex-col gap-1.5">
        <Label htmlFor="date-to">{t("to")}</Label>
        <Input id="date-to" type="date" value={to} onChange={(e) => setTo(e.target.value)} className="h-9 dark:[color-scheme:dark]" />
      </div>
      <Button type="submit" size="lg">
        {t("apply")}
      </Button>
      {(dateFrom || dateTo) && (
        <Button
          type="button"
          variant="ghost"
          size="lg"
          onClick={() => {
            setFrom("");
            setTo("");
            go("", "");
          }}
        >
          {t("reset")}
        </Button>
      )}
      <div className="flex-1" />
      <Button
        type="button"
        variant="outline"
        size="lg"
        disabled={csvRows.length <= 1}
        onClick={() => downloadCsv("tolovlar.csv", toCsv(csvRows))}
      >
        <Download aria-hidden />
        {t("exportCsv")}
      </Button>
    </form>
  );
}
