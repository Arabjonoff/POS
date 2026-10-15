import { useTranslations } from "next-intl";

import { cn } from "@/lib/utils";

const TONES: Record<string, string> = {
  trial: "bg-chart-1/10 text-chart-1",
  active: "bg-chart-2/10 text-chart-2",
  grace: "bg-chart-3/15 text-chart-3",
  readonly: "bg-destructive/10 text-destructive",
  blocked: "bg-destructive text-white",
};

/** Obuna holati rangli badge bilan (`subscription-billing.md`). */
export function StatusBadge({ status }: { status: string }) {
  const t = useTranslations("tenants.status");
  const known = status in TONES;
  return (
    <span
      data-status={status}
      className={cn(
        "inline-flex h-6 items-center rounded-full px-2.5 text-xs font-medium whitespace-nowrap",
        known ? TONES[status] : "bg-muted text-muted-foreground",
      )}
    >
      {known ? t(status as "trial") : status}
    </span>
  );
}
