"use client";

import { KeyRound, LoaderCircle } from "lucide-react";
import { useTranslations } from "next-intl";
import { useState } from "react";

import { resetUserPassword } from "@/app/(app)/tenants/actions";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";

/** Ega/menejer parolini tiklash: tasdiqlash → yangi vaqtinchalik parol (faqat bir marta ko'rinadi). */
export function ResetPassword({ userId, userName }: { userId: string; userName: string }) {
  const t = useTranslations("tenants.users");
  const close = useTranslations("common")("close");
  const [open, setOpen] = useState(false);
  const [pending, setPending] = useState(false);
  const [password, setPassword] = useState<string | null>(null);
  const [failed, setFailed] = useState(false);

  async function confirm() {
    setPending(true);
    const result = await resetUserPassword(userId);
    setPending(false);
    if (result.ok) setPassword(result.data);
    else setFailed(true);
  }

  return (
    <>
      <Button
        variant="ghost"
        size="sm"
        onClick={() => {
          setOpen(true);
          setPassword(null);
          setFailed(false);
        }}
      >
        <KeyRound aria-hidden />
        {t("resetPassword")}
      </Button>
      <Dialog open={open} onOpenChange={setOpen}>
        <DialogContent closeLabel={close}>
          <DialogHeader>
            <DialogTitle>{t("resetTitle", { name: userName })}</DialogTitle>
            <DialogDescription>{password ? t("resetDone") : t("resetText")}</DialogDescription>
          </DialogHeader>
          {password && (
            <p className="bg-muted rounded-lg p-3 text-center font-mono text-lg font-semibold" data-testid="new-password">
              {password}
            </p>
          )}
          {failed && (
            <p role="alert" className="text-destructive text-sm">
              {t("resetFailed")}
            </p>
          )}
          <DialogFooter>
            {password ? (
              <Button size="lg" onClick={() => setOpen(false)}>
                {t("done")}
              </Button>
            ) : (
              <>
                <Button variant="outline" size="lg" onClick={() => setOpen(false)}>
                  {t("cancel")}
                </Button>
                <Button size="lg" onClick={confirm} disabled={pending}>
                  {pending && <LoaderCircle className="animate-spin" aria-hidden />}
                  {t("resetConfirm")}
                </Button>
              </>
            )}
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </>
  );
}
