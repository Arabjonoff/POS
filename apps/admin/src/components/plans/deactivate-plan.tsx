"use client";

import { LoaderCircle, PowerOff } from "lucide-react";
import { useRouter } from "next/navigation";
import { useTranslations } from "next-intl";
import { useState } from "react";

import { deactivatePlan } from "@/app/(app)/plans/actions";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";

/** Tarifni nofaol qilish: yangi mijozlarga taklif qilinmaydi, mavjud obunalar saqlanadi. */
export function DeactivatePlan({ id, name, subscribers }: { id: string; name: string; subscribers: number }) {
  const t = useTranslations("plans");
  const close = useTranslations("common")("close");
  const router = useRouter();
  const [open, setOpen] = useState(false);
  const [pending, setPending] = useState(false);
  const [failed, setFailed] = useState(false);

  async function confirm() {
    setPending(true);
    const result = await deactivatePlan(id);
    setPending(false);
    if (!result.ok) {
      setFailed(true);
      return;
    }
    setOpen(false);
    router.refresh();
  }

  return (
    <>
      <Button
        variant="ghost"
        size="sm"
        aria-label={t("deactivate")}
        title={t("deactivate")}
        onClick={() => {
          setFailed(false);
          setOpen(true);
        }}
      >
        <PowerOff aria-hidden />
        <span className="hidden xl:inline">{t("deactivate")}</span>
      </Button>
      <Dialog open={open} onOpenChange={setOpen}>
        <DialogContent closeLabel={close}>
          <DialogHeader>
            <DialogTitle>{t("deactivateTitle", { name })}</DialogTitle>
            <DialogDescription>{t("deactivateText", { count: subscribers })}</DialogDescription>
          </DialogHeader>
          {failed && (
            <p role="alert" className="text-destructive text-sm">
              {t("errors.failed")}
            </p>
          )}
          <DialogFooter>
            <Button variant="outline" size="lg" onClick={() => setOpen(false)}>
              {t("cancel")}
            </Button>
            <Button variant="destructive" size="lg" onClick={confirm} disabled={pending}>
              {pending && <LoaderCircle className="animate-spin" aria-hidden />}
              {t("deactivate")}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </>
  );
}
