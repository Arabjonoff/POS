"use client";

import { Ban, LoaderCircle, LockOpen } from "lucide-react";
import { useRouter } from "next/navigation";
import { useTranslations } from "next-intl";
import { useState } from "react";

import { blockDevice, unblockDevice } from "@/app/(app)/devices/actions";
import { blockTenant, unblockTenant, type ActionError } from "@/app/(app)/tenants/actions";
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

const ACTIONS = {
  tenant: { block: blockTenant, unblock: unblockTenant, ns: "tenants.block" },
  device: { block: blockDevice, unblock: unblockDevice, ns: "devices.block" },
} as const;

/** Mijoz yoki qurilmani bloklash (sabab majburiy) yoki blokdan chiqarish — tasdiqlash oynasi bilan. */
export function BlockDialog({
  targetId,
  blocked,
  kind = "tenant",
  compact = false,
}: {
  targetId: string;
  blocked: boolean;
  kind?: keyof typeof ACTIONS;
  /** Jadval qatori uchun kichik tugma. */
  compact?: boolean;
}) {
  const actions = ACTIONS[kind];
  const t = useTranslations(actions.ns);
  const close = useTranslations("common")("close");
  const router = useRouter();
  const [open, setOpen] = useState(false);
  const [reason, setReason] = useState("");
  const [missing, setMissing] = useState(false);
  const [failure, setFailure] = useState<ActionError | null>(null);
  const [pending, setPending] = useState(false);

  async function confirm() {
    if (!blocked && !reason.trim()) {
      setMissing(true);
      return;
    }
    setPending(true);
    const result = blocked ? await actions.unblock(targetId, reason) : await actions.block(targetId, reason);
    setPending(false);
    if (!result.ok) {
      setFailure(result.error);
      return;
    }
    setOpen(false);
    setReason("");
    router.refresh();
  }

  return (
    <>
      <Button
        variant={blocked ? "outline" : compact ? "ghost" : "destructive"}
        size={compact ? "sm" : "lg"}
        onClick={() => {
          setOpen(true);
          setFailure(null);
          setMissing(false);
        }}
      >
        {blocked ? <LockOpen aria-hidden /> : <Ban aria-hidden />}
        {blocked ? t("unblock") : t("block")}
      </Button>
      <Dialog open={open} onOpenChange={setOpen}>
        <DialogContent closeLabel={close}>
          <DialogHeader>
            <DialogTitle>{blocked ? t("unblockTitle") : t("blockTitle")}</DialogTitle>
            <DialogDescription>{blocked ? t("unblockText") : t("blockText")}</DialogDescription>
          </DialogHeader>
          <div className="flex flex-col gap-1.5">
            <Label htmlFor="block-reason">{blocked ? t("reasonOptional") : t("reason")}</Label>
            <Textarea
              id="block-reason"
              value={reason}
              onChange={(e) => {
                setReason(e.target.value);
                setMissing(false);
              }}
              aria-invalid={missing}
              autoFocus
            />
            {missing && <p className="text-destructive text-xs">{t("reasonRequired")}</p>}
          </div>
          {failure && (
            <p role="alert" className="text-destructive text-sm">
              {t("failed")}
            </p>
          )}
          <DialogFooter>
            <Button variant="outline" size="lg" onClick={() => setOpen(false)}>
              {t("cancel")}
            </Button>
            <Button variant={blocked ? "default" : "destructive"} size="lg" onClick={confirm} disabled={pending}>
              {pending && <LoaderCircle className="animate-spin" aria-hidden />}
              {blocked ? t("confirmUnblock") : t("confirmBlock")}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </>
  );
}
