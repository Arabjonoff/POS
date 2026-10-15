import { getTranslations } from "next-intl/server";

import { OnboardWizard } from "@/components/tenants/onboard-wizard";
import { listPlans } from "@/lib/platform";

export default async function NewTenantPage() {
  const t = await getTranslations("tenants.new");
  const plans = await listPlans();
  return (
    <div className="mx-auto flex max-w-6xl flex-col gap-6">
      <div className="mx-auto w-full max-w-2xl">
        <h1 className="text-2xl font-semibold tracking-tight">{t("title")}</h1>
        <p className="text-muted-foreground mt-1 text-sm">{t("subtitle")}</p>
      </div>
      <OnboardWizard
        plans={plans.map((p) => ({
          id: p.id ?? "",
          name: p.name,
          priceTiyin: p.price_tiyin_per_month,
          maxDevices: p.max_devices,
        }))}
      />
    </div>
  );
}
