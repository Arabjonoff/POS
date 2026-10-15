"use client";

import { Download, Search } from "lucide-react";
import { usePathname, useRouter, useSearchParams } from "next/navigation";
import { useTranslations } from "next-intl";
import { useEffect, useRef, useState, useTransition } from "react";

import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { downloadCsv, toCsv } from "@/lib/csv";

const STATUSES = ["trial", "active", "grace", "readonly", "blocked"] as const;
const ALL = "all";

/** Qidiruv va holat filtri URL'da (`?search=&status=`) — sahifa server'da qayta o'qiydi. */
export function TenantFilters({ csvRows }: { csvRows: (string | number | null)[][] }) {
  const t = useTranslations("tenants");
  const router = useRouter();
  const pathname = usePathname();
  const params = useSearchParams();
  const [search, setSearch] = useState(params.get("search") ?? "");
  const [pending, startTransition] = useTransition();
  const first = useRef(true);

  function navigate(changes: Record<string, string | null>) {
    const next = new URLSearchParams(params.toString());
    for (const [key, value] of Object.entries(changes)) {
      if (value) next.set(key, value);
      else next.delete(key);
    }
    next.delete("page");
    const query = next.toString();
    startTransition(() => router.replace(query ? `${pathname}?${query}` : pathname));
  }

  // Yozish to'xtagach 300 ms — har harf uchun so'rov yubormaslik.
  useEffect(() => {
    if (first.current) {
      first.current = false;
      return;
    }
    const timer = setTimeout(() => navigate({ search: search.trim() || null }), 300);
    return () => clearTimeout(timer);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [search]);

  const status = params.get("status") ?? ALL;

  return (
    <div className="flex flex-wrap items-center gap-2" aria-busy={pending}>
      <div className="relative min-w-60 flex-1 sm:max-w-sm">
        <Search className="text-muted-foreground pointer-events-none absolute top-1/2 left-2.5 size-4 -translate-y-1/2" aria-hidden />
        <Input
          type="search"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          placeholder={t("searchPlaceholder")}
          aria-label={t("searchPlaceholder")}
          className="h-9 pl-8"
        />
      </div>
      <Select
        value={status}
        onValueChange={(value) => navigate({ status: value === ALL || !value ? null : String(value) })}
        items={[
          { value: ALL, label: t("statusAll") },
          ...STATUSES.map((s) => ({ value: s, label: t(`status.${s}`) })),
        ]}
      >
        <SelectTrigger className="h-9 min-w-44" aria-label={t("statusFilter")}>
          <SelectValue />
        </SelectTrigger>
        <SelectContent>
          <SelectItem value={ALL}>{t("statusAll")}</SelectItem>
          {STATUSES.map((s) => (
            <SelectItem key={s} value={s}>
              {t(`status.${s}`)}
            </SelectItem>
          ))}
        </SelectContent>
      </Select>
      <div className="flex-1" />
      <Button
        variant="outline"
        size="lg"
        disabled={csvRows.length <= 1}
        onClick={() => downloadCsv("mijozlar.csv", toCsv(csvRows))}
      >
        <Download aria-hidden />
        {t("exportCsv")}
      </Button>
    </div>
  );
}
