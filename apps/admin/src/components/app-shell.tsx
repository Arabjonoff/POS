"use client";

import { Menu, Store } from "lucide-react";
import { useTranslations } from "next-intl";
import { useState, type ReactNode } from "react";

import { Button } from "@/components/ui/button";
import { Sheet, SheetContent, SheetTitle, SheetTrigger } from "@/components/ui/sheet";

import type { Admin } from "@/lib/auth/config";

import { AppNav } from "./app-nav";
import { LocaleSwitcher } from "./locale-switcher";
import { ThemeToggle } from "./theme-toggle";
import { UserMenu } from "./user-menu";

function Brand() {
  const t = useTranslations("app");
  return (
    <div className="flex items-center gap-2 px-3 py-2">
      <span className="bg-primary text-primary-foreground grid size-9 place-items-center rounded-lg">
        <Store className="size-5" aria-hidden />
      </span>
      <span className="text-base font-semibold">{t("name")}</span>
    </div>
  );
}

export function AppShell({ admin, children }: { admin: Admin; children: ReactNode }) {
  const t = useTranslations("nav");
  const [open, setOpen] = useState(false);

  return (
    <div className="flex min-h-screen">
      <aside className="bg-sidebar border-sidebar-border sticky top-0 hidden h-screen w-64 shrink-0 flex-col gap-4 border-r p-3 lg:flex">
        <Brand />
        <AppNav />
      </aside>

      <div className="flex min-w-0 flex-1 flex-col">
        <header className="bg-background/80 sticky top-0 z-10 flex h-16 items-center gap-2 border-b px-4 backdrop-blur lg:px-8">
          <Sheet open={open} onOpenChange={setOpen}>
            <SheetTrigger
              render={
                <Button variant="ghost" size="icon-lg" className="lg:hidden" aria-label={t("openMenu")} />
              }
            >
              <Menu className="size-5" aria-hidden />
            </SheetTrigger>
            <SheetContent side="left" className="w-72 p-3">
              <SheetTitle className="sr-only">{t("label")}</SheetTitle>
              <Brand />
              <AppNav onNavigate={() => setOpen(false)} />
            </SheetContent>
          </Sheet>
          <div className="flex-1" />
          <LocaleSwitcher />
          <ThemeToggle />
          <UserMenu admin={admin} />
        </header>
        <main className="flex-1 px-4 py-6 lg:px-8">{children}</main>
      </div>
    </div>
  );
}
