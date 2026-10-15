import { Store } from "lucide-react";
import type { Metadata } from "next";
import { getTranslations } from "next-intl/server";

import { LocaleSwitcher } from "@/components/locale-switcher";
import { LoginForm } from "@/components/login-form";
import { ThemeToggle } from "@/components/theme-toggle";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { safeNext } from "@/lib/auth/config";

export async function generateMetadata(): Promise<Metadata> {
  const t = await getTranslations("login");
  const app = await getTranslations("app");
  return { title: `${t("title")} · ${app("name")}` };
}

export default async function LoginPage({ searchParams }: PageProps<"/login">) {
  const t = await getTranslations("login");
  const app = await getTranslations("app");
  const { next } = await searchParams;
  return (
    <div className="flex min-h-screen flex-col">
      <header className="flex h-16 items-center justify-end gap-2 px-4">
        <LocaleSwitcher />
        <ThemeToggle />
      </header>
      <main className="flex flex-1 items-start justify-center px-4 pt-[10vh] pb-16">
        <Card className="w-full max-w-sm">
          <CardHeader className="items-center gap-3 text-center">
            <span className="bg-primary text-primary-foreground mx-auto grid size-12 place-items-center rounded-xl">
              <Store className="size-6" aria-hidden />
            </span>
            <CardTitle>
              <h1 className="text-xl font-semibold">{t("title")}</h1>
            </CardTitle>
            <CardDescription>{t("subtitle", { app: app("name") })}</CardDescription>
          </CardHeader>
          <CardContent>
            <LoginForm next={safeNext(typeof next === "string" ? next : null)} />
          </CardContent>
        </Card>
      </main>
    </div>
  );
}
