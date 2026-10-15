import { AppShell } from "@/components/app-shell";
import { getCurrentAdmin } from "@/lib/auth/session";

/** Himoyalangan sahifalar: faqat platforma admini. */
export default async function ProtectedLayout({ children }: LayoutProps<"/">) {
  const admin = await getCurrentAdmin();
  return <AppShell admin={admin}>{children}</AppShell>;
}
