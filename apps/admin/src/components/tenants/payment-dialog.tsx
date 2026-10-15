"use client";

import { LoaderCircle, Wallet } from "lucide-react";
import { usePathname, useRouter } from "next/navigation";
import { useTranslations } from "next-intl";
import { useState, type FormEvent } from "react";

import { recordPayment, type PaymentMethod } from "@/app/(app)/tenants/actions";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { parseSom, previewPeriod, tashkentToday } from "@/lib/billing";
import { formatDate, formatMoney, formatMoneyAmount } from "@/lib/format";
import { cn } from "@/lib/utils";

const METHODS: PaymentMethod[] = ["cash", "transfer", "card", "other"];
const MONTH_CHOICES = [1, 3, 6, 12];

export type PaymentDialogProps = {
  tenantId: string;
  tenantName: string;
  /** Tarifning oylik narxi (taklif uchun); tarif noma'lum — `null`. */
  planPriceTiyin: number | null;
  paidUntil: string | null;
  trialEndsAt: string | null;
  /** `?payment=1` bilan kelinganda darhol ochiladi. */
  defaultOpen?: boolean;
};

/** To'lov kiritish: oylar × tarif narxi taklif qilinadi, yangi davr oldindan ko'rinadi. */
export function PaymentDialog({
  tenantId,
  tenantName,
  planPriceTiyin,
  paidUntil,
  trialEndsAt,
  defaultOpen = false,
}: PaymentDialogProps) {
  const t = useTranslations("tenants.payment");
  const methods = useTranslations("tenants.detail.methods");
  const close = useTranslations("common")("close");
  const currency = useTranslations("format")("currency");
  const router = useRouter();
  const pathname = usePathname();
  const suggested = (m: number) => (planPriceTiyin === null ? "" : formatMoneyAmount(planPriceTiyin * m));

  const [open, setOpen] = useState(defaultOpen);
  const [months, setMonths] = useState("1");
  const [amount, setAmount] = useState(suggested(1));
  const [amountTouched, setAmountTouched] = useState(false);
  const [method, setMethod] = useState<PaymentMethod>("cash");
  const [note, setNote] = useState("");
  const [errors, setErrors] = useState<{ amount?: true; months?: true }>({});
  const [failed, setFailed] = useState(false);
  const [pending, setPending] = useState(false);

  const monthCount = /^\d+$/.test(months) ? Number(months) : NaN;
  const monthsValid = Number.isInteger(monthCount) && monthCount >= 1 && monthCount <= 36;
  const preview = monthsValid
    ? previewPeriod({ paid_until: paidUntil, trial_ends_at: trialEndsAt }, monthCount, tashkentToday())
    : null;

  function changeMonths(value: string) {
    setMonths(value);
    setErrors({});
    if (!amountTouched && /^\d+$/.test(value) && Number(value) >= 1) setAmount(suggested(Number(value)));
  }

  function openDialog() {
    setMonths("1");
    setAmount(suggested(1));
    setAmountTouched(false);
    setMethod("cash");
    setNote("");
    setErrors({});
    setFailed(false);
    setOpen(true);
  }

  function changeOpen(next: boolean) {
    setOpen(next);
    // `?payment=1` qayta ochmasin.
    if (!next && defaultOpen) router.replace(`${pathname}?tab=payments`);
  }

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const amountTiyin = parseSom(amount);
    const next = {
      ...(amountTiyin === null ? { amount: true as const } : {}),
      ...(monthsValid ? {} : { months: true as const }),
    };
    setErrors(next);
    if (amountTiyin === null || !monthsValid) return;
    setPending(true);
    const result = await recordPayment(tenantId, { amountTiyin, months: monthCount, method, note });
    setPending(false);
    if (!result.ok) {
      setFailed(true);
      return;
    }
    setOpen(false);
    router.replace(`${pathname}?tab=payments`);
    router.refresh();
  }

  return (
    <>
      <Button size="lg" onClick={openDialog}>
        <Wallet aria-hidden />
        {t("add")}
      </Button>
      <Dialog open={open} onOpenChange={changeOpen}>
        <DialogContent closeLabel={close} className="sm:max-w-md">
          <form onSubmit={submit} noValidate className="flex flex-col gap-4">
            <DialogHeader>
              <DialogTitle>{t("title")}</DialogTitle>
              <DialogDescription>{t("text", { name: tenantName })}</DialogDescription>
            </DialogHeader>

            <div className="flex flex-col gap-1.5">
              <Label htmlFor="payment-months">{t("months")}</Label>
              <div className="flex flex-wrap gap-2">
                {MONTH_CHOICES.map((m) => (
                  <Button
                    key={m}
                    type="button"
                    variant={String(m) === months ? "default" : "outline"}
                    size="lg"
                    className="min-w-11"
                    onClick={() => changeMonths(String(m))}
                    aria-pressed={String(m) === months}
                  >
                    {m}
                  </Button>
                ))}
                <Input
                  id="payment-months"
                  inputMode="numeric"
                  value={months}
                  onChange={(e) => changeMonths(e.target.value)}
                  aria-invalid={Boolean(errors.months)}
                  className="h-9 w-20"
                />
              </div>
              {errors.months && <p className="text-destructive text-xs">{t("errors.months")}</p>}
            </div>

            <div className="flex flex-col gap-1.5">
              <Label htmlFor="payment-amount">{t("amount")}</Label>
              <Input
                id="payment-amount"
                inputMode="decimal"
                value={amount}
                onChange={(e) => {
                  setAmount(e.target.value);
                  setAmountTouched(true);
                  setErrors({});
                }}
                aria-invalid={Boolean(errors.amount)}
                className="h-10 text-base tabular-nums"
              />
              {errors.amount ? (
                <p className="text-destructive text-xs">{t("errors.amount")}</p>
              ) : planPriceTiyin !== null && monthsValid ? (
                <p className="text-muted-foreground text-xs">
                  {t("amountHint", { price: formatMoney(planPriceTiyin, currency), months: monthCount })}
                </p>
              ) : null}
            </div>

            <fieldset className="flex flex-col gap-1.5">
              <legend className="mb-1.5 text-sm font-medium">{t("method")}</legend>
              <div className="grid grid-cols-2 gap-2">
                {METHODS.map((m) => (
                  <label
                    key={m}
                    className={cn(
                      "flex h-10 cursor-pointer items-center gap-2 rounded-lg border px-3 text-sm",
                      method === m && "border-primary ring-primary/30 ring-2",
                    )}
                  >
                    <input
                      type="radio"
                      name="payment-method"
                      checked={method === m}
                      onChange={() => setMethod(m)}
                      className="accent-primary size-4"
                    />
                    {methods(m)}
                  </label>
                ))}
              </div>
            </fieldset>

            <div className="flex flex-col gap-1.5">
              <Label htmlFor="payment-note">{t("note")}</Label>
              <Input id="payment-note" value={note} onChange={(e) => setNote(e.target.value)} className="h-10" />
            </div>

            {preview && (
              <p className="bg-muted rounded-lg p-3 text-sm font-medium" data-testid="payment-preview">
                {t("preview", { from: formatDate(preview.from), to: formatDate(preview.to) })}
              </p>
            )}
            {failed && (
              <p role="alert" className="text-destructive text-sm">
                {t("errors.failed")}
              </p>
            )}

            <DialogFooter>
              <Button type="button" variant="outline" size="lg" onClick={() => changeOpen(false)}>
                {t("cancel")}
              </Button>
              <Button type="submit" size="lg" disabled={pending}>
                {pending && <LoaderCircle className="animate-spin" aria-hidden />}
                {t("save")}
              </Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>
    </>
  );
}
