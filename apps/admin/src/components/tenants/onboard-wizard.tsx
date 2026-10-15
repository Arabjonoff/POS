"use client";

import { Check, Copy, LoaderCircle } from "lucide-react";
import Link from "next/link";
import { useTranslations } from "next-intl";
import { useState, type FormEvent, type ReactNode } from "react";

import {
  onboardTenant,
  type ActionError,
  type OnboardInput,
  type OnboardOutput,
} from "@/app/(app)/tenants/actions";
import { Button, buttonVariants } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { formatMoney } from "@/lib/format";
import { cn } from "@/lib/utils";

export type PlanOption = { id: string; name: string; priceTiyin: number; maxDevices?: number };

type Step = 1 | 2 | 3;

const EMPTY: OnboardInput = {
  name: "",
  address: "",
  notes: "",
  ownerPhone: "",
  ownerName: "",
  ownerPassword: "",
  plan: "",
  trialDays: 14,
};

export const MIN_PASSWORD = 8;

/** Qadam bo'yicha tekshiruv: xato kalitlari (`tenants.new.errors.*`). */
export function validateStep(step: Step, input: OnboardInput, manualPassword: boolean): string[] {
  const errors: string[] = [];
  if (step === 1 && !input.name.trim()) errors.push("name");
  if (step === 2) {
    if (input.ownerPhone.replace(/\D/g, "").length < 9) errors.push("phone");
    if (!input.ownerName.trim()) errors.push("ownerName");
    if (manualPassword && input.ownerPassword.length < MIN_PASSWORD) errors.push("password");
  }
  if (step === 3) {
    if (!input.plan) errors.push("plan");
    if (!Number.isInteger(input.trialDays) || input.trialDays < 0 || input.trialDays > 90) {
      errors.push("trialDays");
    }
  }
  return errors;
}

function Field({
  id,
  label,
  error,
  hint,
  children,
}: {
  id: string;
  label: string;
  error?: string;
  hint?: string;
  children: ReactNode;
}) {
  return (
    <div className="flex flex-col gap-1.5">
      <Label htmlFor={id}>{label}</Label>
      {children}
      {error ? (
        <p className="text-destructive text-xs" id={`${id}-error`}>
          {error}
        </p>
      ) : hint ? (
        <p className="text-muted-foreground text-xs">{hint}</p>
      ) : null}
    </div>
  );
}

/** Yangi mijoz ustasi: do'kon → ega → tarif va sinov (spec: admin-dashboard.md, 4-band). */
export function OnboardWizard({ plans }: { plans: PlanOption[] }) {
  const t = useTranslations("tenants.new");
  const currency = useTranslations("format")("currency");
  const [step, setStep] = useState<Step>(1);
  const [input, setInput] = useState<OnboardInput>({ ...EMPTY, plan: plans[0]?.id ?? "" });
  const [manualPassword, setManualPassword] = useState(false);
  const [errors, setErrors] = useState<string[]>([]);
  const [failure, setFailure] = useState<ActionError | null>(null);
  const [pending, setPending] = useState(false);
  const [result, setResult] = useState<OnboardOutput | null>(null);

  const set = <K extends keyof OnboardInput>(key: K, value: OnboardInput[K]) => {
    setInput((prev) => ({ ...prev, [key]: value }));
    setErrors([]);
    setFailure(null);
  };
  const error = (key: string) => (errors.includes(key) ? t(`errors.${key}` as "errors.name") : undefined);

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const problems = validateStep(step, input, manualPassword);
    if (problems.length) {
      setErrors(problems);
      return;
    }
    if (step < 3) {
      setStep((step + 1) as Step);
      return;
    }
    setPending(true);
    const response = await onboardTenant({
      ...input,
      ownerPassword: manualPassword ? input.ownerPassword : "",
    });
    setPending(false);
    if (response.ok) {
      setResult(response.data);
      return;
    }
    if (response.error === "phone_taken") {
      setStep(2);
      setErrors(["phoneTaken"]);
      return;
    }
    setFailure(response.error);
  }

  if (result) return <OnboardResult result={result} onAgain={() => {
    setResult(null);
    setInput({ ...EMPTY, plan: plans[0]?.id ?? "" });
    setManualPassword(false);
    setStep(1);
  }} />;

  const steps = [t("stepStore"), t("stepOwner"), t("stepPlan")];

  return (
    <Card className="mx-auto w-full max-w-2xl">
      <CardHeader>
        <ol className="flex flex-wrap items-center gap-2 text-sm" aria-label={t("steps")}>
          {steps.map((label, i) => {
            const n = (i + 1) as Step;
            return (
              <li
                key={label}
                aria-current={n === step ? "step" : undefined}
                className={cn(
                  "flex items-center gap-2 rounded-full px-3 py-1",
                  n === step ? "bg-primary text-primary-foreground" : "text-muted-foreground",
                )}
              >
                <span
                  className={cn(
                    "grid size-5 place-items-center rounded-full border text-xs",
                    n < step && "bg-chart-2 border-chart-2 text-white",
                  )}
                >
                  {n < step ? <Check className="size-3" aria-hidden /> : n}
                </span>
                {label}
              </li>
            );
          })}
        </ol>
      </CardHeader>
      <CardContent>
        <form onSubmit={submit} noValidate className="flex flex-col gap-4">
          {step === 1 && (
            <>
              <Field id="name" label={t("name")} error={error("name")}>
                <Input
                  id="name"
                  value={input.name}
                  onChange={(e) => set("name", e.target.value)}
                  aria-invalid={Boolean(error("name"))}
                  className="h-10"
                  autoFocus
                />
              </Field>
              <Field id="address" label={t("address")}>
                <Input
                  id="address"
                  value={input.address}
                  onChange={(e) => set("address", e.target.value)}
                  className="h-10"
                />
              </Field>
              <Field id="notes" label={t("notes")}>
                <Textarea id="notes" value={input.notes} onChange={(e) => set("notes", e.target.value)} />
              </Field>
            </>
          )}

          {step === 2 && (
            <>
              <Field
                id="owner-phone"
                label={t("ownerPhone")}
                error={error("phone") ?? error("phoneTaken")}
              >
                <Input
                  id="owner-phone"
                  type="tel"
                  inputMode="tel"
                  placeholder="90 123 45 67"
                  value={input.ownerPhone}
                  onChange={(e) => set("ownerPhone", e.target.value)}
                  aria-invalid={Boolean(error("phone") ?? error("phoneTaken"))}
                  className="h-10"
                  autoFocus
                />
              </Field>
              <Field id="owner-name" label={t("ownerName")} error={error("ownerName")}>
                <Input
                  id="owner-name"
                  value={input.ownerName}
                  onChange={(e) => set("ownerName", e.target.value)}
                  aria-invalid={Boolean(error("ownerName"))}
                  className="h-10"
                />
              </Field>
              <fieldset className="flex flex-col gap-2">
                <legend className="mb-1.5 text-sm font-medium">{t("password")}</legend>
                <label className="flex items-center gap-2 text-sm">
                  <input
                    type="radio"
                    name="password-mode"
                    checked={!manualPassword}
                    onChange={() => setManualPassword(false)}
                    className="accent-primary size-4"
                  />
                  {t("passwordGenerate")}
                </label>
                <label className="flex items-center gap-2 text-sm">
                  <input
                    type="radio"
                    name="password-mode"
                    checked={manualPassword}
                    onChange={() => setManualPassword(true)}
                    className="accent-primary size-4"
                  />
                  {t("passwordManual")}
                </label>
                {manualPassword && (
                  <Field id="owner-password" label={t("passwordLabel")} error={error("password")}>
                    <Input
                      id="owner-password"
                      type="text"
                      autoComplete="off"
                      value={input.ownerPassword}
                      onChange={(e) => set("ownerPassword", e.target.value)}
                      aria-invalid={Boolean(error("password"))}
                      className="h-10"
                    />
                  </Field>
                )}
              </fieldset>
            </>
          )}

          {step === 3 && (
            <>
              <fieldset className="flex flex-col gap-2">
                <legend className="mb-1.5 text-sm font-medium">{t("plan")}</legend>
                {plans.length === 0 && <p className="text-destructive text-sm">{t("noPlans")}</p>}
                {plans.map((plan) => (
                  <label
                    key={plan.id}
                    className={cn(
                      "flex cursor-pointer items-center gap-3 rounded-lg border p-3 text-sm",
                      input.plan === plan.id && "border-primary ring-primary/30 ring-2",
                    )}
                  >
                    <input
                      type="radio"
                      name="plan"
                      value={plan.id}
                      checked={input.plan === plan.id}
                      onChange={() => set("plan", plan.id)}
                      className="accent-primary size-4"
                    />
                    <span className="flex-1 font-medium">{plan.name}</span>
                    <span className="text-muted-foreground tabular-nums">
                      {t("perMonth", { price: formatMoney(plan.priceTiyin, currency) })}
                    </span>
                  </label>
                ))}
                {error("plan") && <p className="text-destructive text-xs">{error("plan")}</p>}
              </fieldset>
              <Field id="trial-days" label={t("trialDays")} error={error("trialDays")} hint={t("trialHint")}>
                <Input
                  id="trial-days"
                  type="number"
                  min={0}
                  max={90}
                  inputMode="numeric"
                  value={Number.isNaN(input.trialDays) ? "" : input.trialDays}
                  onChange={(e) => set("trialDays", e.target.value === "" ? Number.NaN : Number(e.target.value))}
                  aria-invalid={Boolean(error("trialDays"))}
                  className="h-10 w-32"
                />
              </Field>
            </>
          )}

          {failure && (
            <p role="alert" className="text-destructive text-sm">
              {t(`failure.${failure}`)}
            </p>
          )}

          <div className="flex justify-between gap-2 pt-2">
            {step > 1 ? (
              <Button type="button" variant="outline" size="lg" onClick={() => setStep((step - 1) as Step)}>
                {t("back")}
              </Button>
            ) : (
              <Link href="/tenants" className={buttonVariants({ variant: "outline", size: "lg" })}>
                {t("cancel")}
              </Link>
            )}
            <Button type="submit" size="lg" disabled={pending}>
              {pending && <LoaderCircle className="animate-spin" aria-hidden />}
              {step < 3 ? t("next") : t("create")}
            </Button>
          </div>
        </form>
      </CardContent>
    </Card>
  );
}

/** Kirish ma'lumotlari — egaga yuborish uchun nusxa olinadi (parol faqat shu yerda ko'rinadi). */
function OnboardResult({ result, onAgain }: { result: OnboardOutput; onAgain: () => void }) {
  const t = useTranslations("tenants.new");
  const [copied, setCopied] = useState(false);
  const password = result.temporaryPassword ?? t("passwordYours");
  const text = [
    `${t("resultStore")}: ${result.tenantName}`,
    `${t("resultPhone")}: ${result.ownerPhone}`,
    `${t("resultPassword")}: ${password}`,
  ].join("\n");

  async function copy() {
    await navigator.clipboard.writeText(text);
    setCopied(true);
  }

  return (
    <Card className="mx-auto w-full max-w-2xl" data-testid="onboard-result">
      <CardHeader>
        <CardTitle>
          <h2 className="text-lg font-semibold">{t("resultTitle")}</h2>
        </CardTitle>
        <CardDescription>{t("resultText")}</CardDescription>
      </CardHeader>
      <CardContent className="flex flex-col gap-4">
        <dl className="bg-muted grid grid-cols-[auto_1fr] gap-x-4 gap-y-2 rounded-lg p-4 text-sm">
          <dt className="text-muted-foreground">{t("resultStore")}</dt>
          <dd className="font-medium">{result.tenantName}</dd>
          <dt className="text-muted-foreground">{t("resultPhone")}</dt>
          <dd className="font-medium tabular-nums">{result.ownerPhone}</dd>
          <dt className="text-muted-foreground">{t("resultPassword")}</dt>
          <dd className="font-mono font-semibold" data-testid="temporary-password">
            {password}
          </dd>
        </dl>
        {result.temporaryPassword && <p className="text-muted-foreground text-xs">{t("resultWarning")}</p>}
        <div className="flex flex-wrap gap-2">
          <Button size="lg" onClick={copy}>
            {copied ? <Check aria-hidden /> : <Copy aria-hidden />}
            {copied ? t("copied") : t("copy")}
          </Button>
          <Link href={`/tenants/${result.tenantId}`} className={buttonVariants({ variant: "outline", size: "lg" })}>
            {t("openTenant")}
          </Link>
          <Button variant="ghost" size="lg" onClick={onAgain}>
            {t("addAnother")}
          </Button>
        </div>
      </CardContent>
    </Card>
  );
}
