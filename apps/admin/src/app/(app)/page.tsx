import { Dashboard } from "@/components/dashboard/dashboard";
import { getStats } from "@/lib/platform";

export default async function HomePage() {
  const stats = await getStats();
  return <Dashboard stats={stats} />;
}
