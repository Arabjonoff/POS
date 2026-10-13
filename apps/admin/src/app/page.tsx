import { LayoutDashboard } from "lucide-react";
import { getTranslations } from "next-intl/server";

import { Card, CardContent } from "@/components/ui/card";

export default async function HomePage() {
  const t = await getTranslations("home");
  return (
    <div className="mx-auto flex max-w-6xl flex-col gap-6">
      <div>
        <h1 className="text-2xl font-semibold tracking-tight">{t("title")}</h1>
        <p className="text-muted-foreground mt-1 text-sm">{t("subtitle")}</p>
      </div>
      <Card>
        <CardContent className="flex flex-col items-center gap-3 py-16 text-center">
          <span className="bg-accent text-accent-foreground grid size-12 place-items-center rounded-full">
            <LayoutDashboard className="size-6" aria-hidden />
          </span>
          <h2 className="text-lg font-semibold">{t("emptyTitle")}</h2>
          <p className="text-muted-foreground max-w-md text-sm">{t("emptyText")}</p>
        </CardContent>
      </Card>
    </div>
  );
}
