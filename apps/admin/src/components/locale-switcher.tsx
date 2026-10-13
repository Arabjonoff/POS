"use client";

import { useRouter } from "next/navigation";
import { useLocale, useTranslations } from "next-intl";
import { useTransition } from "react";

import { cn } from "@/lib/utils";
import { locales, persistLocale, type Locale } from "@/i18n/config";

export function LocaleSwitcher() {
  const t = useTranslations("header");
  const current = useLocale();
  const router = useRouter();
  const [pending, startTransition] = useTransition();

  function choose(locale: Locale) {
    persistLocale(locale);
    startTransition(() => router.refresh());
  }

  return (
    <div role="group" aria-label={t("language")} className="flex rounded-lg border p-0.5">
      {locales.map((locale) => (
        <button
          key={locale}
          type="button"
          disabled={pending}
          aria-pressed={current === locale}
          onClick={() => choose(locale)}
          className={cn(
            "h-9 min-w-11 rounded-md px-2 text-xs font-semibold uppercase transition-colors",
            "focus-visible:ring-ring/50 outline-none focus-visible:ring-3",
            current === locale
              ? "bg-primary text-primary-foreground"
              : "text-muted-foreground hover:text-foreground",
          )}
        >
          {locale}
        </button>
      ))}
    </div>
  );
}
