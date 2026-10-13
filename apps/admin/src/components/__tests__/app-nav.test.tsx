import { screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import { renderWithIntl } from "@/test-utils";

import { AppNav } from "../app-nav";
import { isActive, navItems } from "../nav-items";

describe("AppNav", () => {
  it("renders every section in Uzbek and marks the current page", () => {
    renderWithIntl(<AppNav />);
    expect(screen.getAllByRole("link")).toHaveLength(navItems.length);
    expect(screen.getByRole("link", { name: "Bosh sahifa" })).toHaveAttribute("aria-current", "page");
    expect(screen.getByRole("link", { name: "Mijozlar" })).not.toHaveAttribute("aria-current");
  });

  it("renders Russian labels", () => {
    renderWithIntl(<AppNav />, "ru");
    expect(screen.getByRole("link", { name: "Клиенты" })).toBeInTheDocument();
  });
});

describe("isActive", () => {
  it("matches only the root for /", () => {
    expect(isActive("/", "/")).toBe(true);
    expect(isActive("/tenants", "/")).toBe(false);
  });

  it("matches nested routes", () => {
    expect(isActive("/tenants/123", "/tenants")).toBe(true);
    expect(isActive("/tenants-x", "/tenants")).toBe(false);
  });
});
