import {
  CreditCard,
  LayoutDashboard,
  Layers,
  MonitorSmartphone,
  ScrollText,
  Settings,
  Store,
  type LucideIcon,
} from "lucide-react";

export type NavItem = {
  href: string;
  /** `nav.*` tarjima kaliti */
  labelKey: "dashboard" | "tenants" | "plans" | "payments" | "devices" | "audit" | "settings";
  icon: LucideIcon;
};

export const navItems: NavItem[] = [
  { href: "/", labelKey: "dashboard", icon: LayoutDashboard },
  { href: "/tenants", labelKey: "tenants", icon: Store },
  { href: "/plans", labelKey: "plans", icon: Layers },
  { href: "/payments", labelKey: "payments", icon: CreditCard },
  { href: "/devices", labelKey: "devices", icon: MonitorSmartphone },
  { href: "/audit", labelKey: "audit", icon: ScrollText },
  { href: "/settings", labelKey: "settings", icon: Settings },
];

export function isActive(pathname: string, href: string): boolean {
  if (href === "/") return pathname === "/";
  return pathname === href || pathname.startsWith(`${href}/`);
}
