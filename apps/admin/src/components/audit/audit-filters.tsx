"use client";

import { usePathname, useRouter } from "next/navigation";
import { useTranslations } from "next-intl";
import { useTransition } from "react";

import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";

export const AUDIT_ACTIONS = [
  "tenant.create",
  "tenant.update",
  "tenant.block",
  "tenant.unblock",
  "subscription.create",
  "subscription.update",
  "payment.create",
  "payment.reverse",
  "plan.create",
  "plan.update",
  "plan.deactivate",
  "user.create",
  "user.reset_password",
  "device.block",
  "device.unblock",
] as const;

export const AUDIT_TARGETS = ["tenant", "subscription", "subscriptionpayment", "plan", "user", "device"] as const;

const ALL = "all";

/** Amal va obyekt turi filtri URL'da (`?action=&target_type=`). */
export function AuditFilters({ action, targetType }: { action: string; targetType: string }) {
  const t = useTranslations("audit");
  const router = useRouter();
  const pathname = usePathname();
  const [pending, startTransition] = useTransition();

  function navigate(key: "action" | "target_type", value: string) {
    const query = new URLSearchParams(window.location.search);
    if (value && value !== ALL) query.set(key, value);
    else query.delete(key);
    query.delete("page");
    const text = query.toString();
    startTransition(() => router.replace(text ? `${pathname}?${text}` : pathname));
  }

  const actionItems = [
    { value: ALL, label: t("allActions") },
    ...AUDIT_ACTIONS.map((a) => ({ value: a, label: t(`actions.${a.replace(".", "_")}`) })),
  ];
  const targetItems = [
    { value: ALL, label: t("allTargets") },
    ...AUDIT_TARGETS.map((x) => ({ value: x, label: t(`targets.${x}`) })),
  ];

  return (
    <div className="flex flex-wrap items-center gap-2" aria-busy={pending}>
      <Select value={action || ALL} onValueChange={(v) => navigate("action", String(v ?? ""))} items={actionItems}>
        <SelectTrigger className="h-9 min-w-56" aria-label={t("actionFilter")}>
          <SelectValue />
        </SelectTrigger>
        <SelectContent>
          {actionItems.map((item) => (
            <SelectItem key={item.value} value={item.value}>
              {item.label}
            </SelectItem>
          ))}
        </SelectContent>
      </Select>
      <Select
        value={targetType || ALL}
        onValueChange={(v) => navigate("target_type", String(v ?? ""))}
        items={targetItems}
      >
        <SelectTrigger className="h-9 min-w-44" aria-label={t("targetFilter")}>
          <SelectValue />
        </SelectTrigger>
        <SelectContent>
          {targetItems.map((item) => (
            <SelectItem key={item.value} value={item.value}>
              {item.label}
            </SelectItem>
          ))}
        </SelectContent>
      </Select>
    </div>
  );
}
