"use client";

import { LogOut, UserRound } from "lucide-react";
import { useRouter } from "next/navigation";
import { useTranslations } from "next-intl";
import { useState } from "react";

import { Button } from "@/components/ui/button";
import type { Admin } from "@/lib/auth/config";

/** Admin ismi va "Chiqish" (cookie'lar route handler'da o'chiriladi). */
export function UserMenu({ admin }: { admin: Admin }) {
  const t = useTranslations("header");
  const router = useRouter();
  const [pending, setPending] = useState(false);

  async function logout() {
    setPending(true);
    try {
      await fetch("/api/auth/logout", { method: "POST" });
    } finally {
      router.replace("/login");
      router.refresh();
    }
  }

  return (
    <div className="flex items-center gap-2">
      <span className="text-muted-foreground hidden items-center gap-2 text-sm sm:flex">
        <UserRound className="size-4" aria-hidden />
        <span data-testid="admin-name" className="text-foreground font-medium">
          {admin.fullName}
        </span>
      </span>
      <Button
        variant="ghost"
        size="lg"
        onClick={logout}
        disabled={pending}
        aria-label={t("logout")}
        className="h-9"
      >
        <LogOut className="size-5" aria-hidden />
        <span className="hidden md:inline">{t("logout")}</span>
      </Button>
    </div>
  );
}
