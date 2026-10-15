import { Construction } from "lucide-react";
import { notFound } from "next/navigation";
import { getTranslations } from "next-intl/server";

import { navItems } from "@/components/nav-items";
import { Card, CardContent } from "@/components/ui/card";

/** Menyudagi hali qurilmagan bo'lim (keyingi vazifalarda o'z sahifasi bilan almashtiriladi). */
export default async function SectionPlaceholder({ params }: PageProps<"/[section]">) {
  const { section } = await params;
  const item = navItems.find((i) => i.href !== "/" && i.href === `/${section}`);
  if (!item) notFound();
  const nav = await getTranslations("nav");
  const t = await getTranslations("section");
  return (
    <div className="mx-auto flex max-w-6xl flex-col gap-6">
      <h1 className="text-2xl font-semibold tracking-tight">{nav(item.labelKey)}</h1>
      <Card>
        <CardContent className="flex flex-col items-center gap-3 py-16 text-center">
          <span className="bg-accent text-accent-foreground grid size-12 place-items-center rounded-full">
            <Construction className="size-6" aria-hidden />
          </span>
          <h2 className="text-lg font-semibold">{t("soonTitle")}</h2>
          <p className="text-muted-foreground max-w-md text-sm">{t("soonText")}</p>
        </CardContent>
      </Card>
    </div>
  );
}
