"use client";

import { LoaderCircle, Pencil, Plus } from "lucide-react";
import { useRouter } from "next/navigation";
import { useTranslations } from "next-intl";
import { useState, type FormEvent } from "react";

import { savePlan } from "@/app/(app)/plans/actions";
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
import { parseSom } from "@/lib/billing";
import { formatMoneyInput } from "@/lib/format";

export type PlanValues = {
  id: string | null;
  name: string;
  priceTiyin: number;
  maxDevices: number;
  maxUsers: number;
  isActive: boolean;
};

type Errors = Partial<Record<"name" | "price" | "maxDevices" | "maxUsers", true>>;

function positiveInt(text: string): number | null {
  return /^\d+$/.test(text.trim()) && Number(text) >= 1 ? Number(text) : null;
}

/** Tarif yaratish yoki tahrirlash. [plan] berilmasa — yangi tarif. */
export function PlanDialog({ plan }: { plan?: PlanValues }) {
  const t = useTranslations("plans");
  const close = useTranslations("common")("close");
  const router = useRouter();
  const [open, setOpen] = useState(false);
  const [name, setName] = useState("");
  const [price, setPrice] = useState("");
  const [devices, setDevices] = useState("1");
  const [users, setUsers] = useState("3");
  const [active, setActive] = useState(true);
  const [errors, setErrors] = useState<Errors>({});
  const [failed, setFailed] = useState(false);
  const [pending, setPending] = useState(false);

  function start() {
    setName(plan?.name ?? "");
    setPrice(plan ? formatMoneyInput(plan.priceTiyin) : "");
    setDevices(String(plan?.maxDevices ?? 1));
    setUsers(String(plan?.maxUsers ?? 3));
    setActive(plan?.isActive ?? true);
    setErrors({});
    setFailed(false);
    setOpen(true);
  }

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const priceTiyin = parseSom(price);
    const maxDevices = positiveInt(devices);
    const maxUsers = positiveInt(users);
    const next: Errors = {
      ...(name.trim() ? {} : { name: true }),
      ...(priceTiyin === null ? { price: true } : {}),
      ...(maxDevices === null ? { maxDevices: true } : {}),
      ...(maxUsers === null ? { maxUsers: true } : {}),
    };
    setErrors(next);
    if (Object.keys(next).length || priceTiyin === null || maxDevices === null || maxUsers === null) return;
    setPending(true);
    const result = await savePlan(plan?.id ?? null, {
      name,
      priceTiyin,
      maxDevices,
      maxUsers,
      isActive: active,
    });
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
      {plan ? (
        <Button variant="ghost" size="sm" onClick={start}>
          <Pencil aria-hidden />
          {t("edit")}
        </Button>
      ) : (
        <Button size="lg" onClick={start}>
          <Plus aria-hidden />
          {t("add")}
        </Button>
      )}
      <Dialog open={open} onOpenChange={setOpen}>
        <DialogContent closeLabel={close}>
          <form onSubmit={submit} noValidate className="flex flex-col gap-4">
            <DialogHeader>
              <DialogTitle>{plan ? t("editTitle") : t("addTitle")}</DialogTitle>
              <DialogDescription>{t("dialogText")}</DialogDescription>
            </DialogHeader>
            <div className="flex flex-col gap-1.5">
              <Label htmlFor="plan-name">{t("name")}</Label>
              <Input
                id="plan-name"
                value={name}
                onChange={(e) => setName(e.target.value)}
                aria-invalid={Boolean(errors.name)}
                className="h-10"
                autoFocus
              />
              {errors.name && <p className="text-destructive text-xs">{t("errors.name")}</p>}
            </div>
            <div className="flex flex-col gap-1.5">
              <Label htmlFor="plan-price">{t("pricePerMonth")}</Label>
              <Input
                id="plan-price"
                inputMode="decimal"
                placeholder="99 000"
                value={price}
                onChange={(e) => setPrice(e.target.value)}
                aria-invalid={Boolean(errors.price)}
                className="h-10"
              />
              {errors.price && <p className="text-destructive text-xs">{t("errors.price")}</p>}
            </div>
            <div className="grid grid-cols-2 gap-3">
              <div className="flex flex-col gap-1.5">
                <Label htmlFor="plan-devices">{t("maxDevices")}</Label>
                <Input
                  id="plan-devices"
                  inputMode="numeric"
                  value={devices}
                  onChange={(e) => setDevices(e.target.value)}
                  aria-invalid={Boolean(errors.maxDevices)}
                  className="h-10"
                />
              </div>
              <div className="flex flex-col gap-1.5">
                <Label htmlFor="plan-users">{t("maxUsers")}</Label>
                <Input
                  id="plan-users"
                  inputMode="numeric"
                  value={users}
                  onChange={(e) => setUsers(e.target.value)}
                  aria-invalid={Boolean(errors.maxUsers)}
                  className="h-10"
                />
              </div>
            </div>
            {(errors.maxDevices || errors.maxUsers) && (
              <p className="text-destructive text-xs">{t("errors.limits")}</p>
            )}
            <label className="flex items-center gap-2 text-sm">
              <input
                type="checkbox"
                checked={active}
                onChange={(e) => setActive(e.target.checked)}
                className="accent-primary size-4"
              />
              {t("activeLabel")}
            </label>
            {failed && (
              <p role="alert" className="text-destructive text-sm">
                {t("errors.failed")}
              </p>
            )}
            <DialogFooter>
              <Button type="button" variant="outline" size="lg" onClick={() => setOpen(false)}>
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
