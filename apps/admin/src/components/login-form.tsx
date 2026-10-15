"use client";

import { LoaderCircle } from "lucide-react";
import { useRouter } from "next/navigation";
import { useTranslations } from "next-intl";
import { useState, type FormEvent } from "react";

import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";

const ERRORS = {
  invalid_credentials: "invalidCredentials",
  not_admin: "notAdmin",
  too_many_attempts: "tooMany",
  bad_request: "required",
  unavailable: "unavailable",
} as const;

type ErrorKey = (typeof ERRORS)[keyof typeof ERRORS];

/** Telefon + parol. Muvaffaqiyatli — `next` sahifaga. */
export function LoginForm({ next }: { next: string }) {
  const t = useTranslations("login");
  const router = useRouter();
  const [phone, setPhone] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<ErrorKey | null>(null);
  const [pending, setPending] = useState(false);

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!phone.trim() || !password) {
      setError("required");
      return;
    }
    setPending(true);
    setError(null);
    try {
      const response = await fetch("/api/auth/login", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ phone: phone.trim(), password }),
      });
      if (response.ok) {
        router.replace(next);
        router.refresh();
        return;
      }
      const body = (await response.json().catch(() => ({}))) as { error?: string };
      setError(ERRORS[body.error as keyof typeof ERRORS] ?? "unavailable");
    } catch {
      setError("unavailable");
    }
    setPending(false);
  }

  return (
    <form onSubmit={submit} noValidate className="flex flex-col gap-4">
      <label className="flex flex-col gap-1.5 text-sm font-medium">
        {t("phone")}
        <Input
          name="phone"
          type="tel"
          inputMode="tel"
          autoComplete="username"
          placeholder={t("phonePlaceholder")}
          value={phone}
          onChange={(e) => setPhone(e.target.value)}
          aria-invalid={error === "invalidCredentials" || (error === "required" && !phone.trim())}
          className="h-11"
          autoFocus
        />
      </label>
      <label className="flex flex-col gap-1.5 text-sm font-medium">
        {t("password")}
        <Input
          name="password"
          type="password"
          autoComplete="current-password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          aria-invalid={error === "invalidCredentials" || (error === "required" && !password)}
          className="h-11"
        />
      </label>
      {error && (
        <p role="alert" className="text-destructive text-sm">
          {t(`errors.${error}`)}
        </p>
      )}
      <Button type="submit" size="lg" className="h-11" disabled={pending}>
        {pending && <LoaderCircle className="size-4 animate-spin" aria-hidden />}
        {pending ? t("submitting") : t("submit")}
      </Button>
    </form>
  );
}
