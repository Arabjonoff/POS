"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { useTranslations } from "next-intl";

import { cn } from "@/lib/utils";

import { isActive, navItems } from "./nav-items";

export function AppNav({ onNavigate }: { onNavigate?: () => void }) {
  const t = useTranslations("nav");
  const pathname = usePathname() ?? "/";

  return (
    <nav aria-label={t("label")} className="flex flex-col gap-1">
      {navItems.map(({ href, labelKey, icon: Icon }) => {
        const active = isActive(pathname, href);
        return (
          <Link
            key={href}
            href={href}
            onClick={onNavigate}
            aria-current={active ? "page" : undefined}
            className={cn(
              "flex h-11 items-center gap-3 rounded-lg px-3 text-sm font-medium transition-colors",
              "focus-visible:ring-ring/50 outline-none focus-visible:ring-3",
              active
                ? "bg-sidebar-accent text-sidebar-accent-foreground"
                : "text-muted-foreground hover:bg-muted hover:text-foreground",
            )}
          >
            <Icon className="size-5 shrink-0" aria-hidden />
            {t(labelKey)}
          </Link>
        );
      })}
    </nav>
  );
}
