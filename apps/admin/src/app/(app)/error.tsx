"use client";

import { TriangleAlert } from "lucide-react";
import { useTranslations } from "next-intl";

import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";

/** Server (Django) javob bermasa yoki xato bersa. */
export default function ErrorPage({ reset }: { error: Error & { digest?: string }; reset: () => void }) {
  const t = useTranslations("errors");
  return (
    <div className="mx-auto flex max-w-6xl flex-col gap-6">
      <Card>
        <CardContent className="flex flex-col items-center gap-3 py-16 text-center" role="alert">
          <span className="bg-destructive/10 text-destructive grid size-12 place-items-center rounded-full">
            <TriangleAlert className="size-6" aria-hidden />
          </span>
          <h1 className="text-lg font-semibold">{t("loadTitle")}</h1>
          <p className="text-muted-foreground max-w-md text-sm">{t("loadText")}</p>
          <Button size="lg" onClick={reset}>
            {t("retry")}
          </Button>
        </CardContent>
      </Card>
    </div>
  );
}
