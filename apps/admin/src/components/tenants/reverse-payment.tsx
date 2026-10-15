"use client";

import { LoaderCircle, Undo2 } from "lucide-react";
import { useRouter } from "next/navigation";
import { useTranslations } from "next-intl";
import { useState } from "react";

import { reversePayment, type ActionError } from "@/app/(app)/tenants/actions";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";

/** Oxirgi to'lovni bekor qilish — teskari yozuv, sabab majburiy. */
export function ReversePayment({ paymentId }: { paymentId: string }) {
  const t = useTranslations("tenants.payment");
  const close = useTranslations("common")("close");
  const router = useRouter();
  const [open, setOpen] = useState(false);
  const [note, setNote] = useState("");
  const [missing, setMissing] = useState(false);
  const [failure, setFailure] = useState<ActionError | null>(null);
  const [pending, setPending] = useState(false);

  async function confirm() {
    if (!note.trim()) {
      setMissing(true);
      return;
    }
    setPending(true);
    const result = await reversePayment(paymentId, note);
    setPending(false);
    if (!result.ok) {
      setFailure(result.error);
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
        onClick={() => {
          setNote("");
          setMissing(false);
          setFailure(null);
          setOpen(true);
        }}
      >
        <Undo2 aria-hidden />
        {t("reverse")}
      </Button>
      <Dialog open={open} onOpenChange={setOpen}>
        <DialogContent closeLabel={close}>
          <DialogHeader>
            <DialogTitle>{t("reverseTitle")}</DialogTitle>
            <DialogDescription>{t("reverseText")}</DialogDescription>
          </DialogHeader>
          <div className="flex flex-col gap-1.5">
            <Label htmlFor="reverse-note">{t("reverseNote")}</Label>
            <Textarea
              id="reverse-note"
              value={note}
              onChange={(e) => {
                setNote(e.target.value);
                setMissing(false);
              }}
              aria-invalid={missing}
              autoFocus
            />
            {missing && <p className="text-destructive text-xs">{t("reverseNoteRequired")}</p>}
          </div>
          {failure && (
            <p role="alert" className="text-destructive text-sm">
              {failure === "only_latest_payment" ? t("onlyLatest") : t("errors.failed")}
            </p>
          )}
          <DialogFooter>
            <Button variant="outline" size="lg" onClick={() => setOpen(false)}>
              {t("cancel")}
            </Button>
            <Button variant="destructive" size="lg" onClick={confirm} disabled={pending}>
              {pending && <LoaderCircle className="animate-spin" aria-hidden />}
              {t("reverseConfirm")}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </>
  );
}
