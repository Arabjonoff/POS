// E2E uchun soxta Django API (xotirada). Haqiqiy kontrakt: docs/specs/auth-roles.md,
// docs/specs/platform-api.md. Ishga tushirish: `node e2e/mock-api.mjs`.
// Testlar parallel ishlaydi — har test o'z nomlari/telefonlari bilan yozuv yaratadi.
import { randomUUID } from "node:crypto";
import { createServer } from "node:http";

const port = Number(process.env.E2E_API_PORT ?? 3199);

// --- Hisoblar (telefon → parol + foydalanuvchi) ---
const accounts = {
  "998901234567": {
    password: "admin-parol",
    user: {
      id: "00000000-0000-7000-8000-000000000001",
      phone: "+998901234567",
      full_name: "Platforma Admin",
      role: "platform_admin",
      tenant: null,
    },
  },
  // Statistika so'rovi 500 qaytaradigan admin (xato holatini sinash uchun).
  "998911111111": {
    password: "admin-parol",
    user: {
      id: "00000000-0000-7000-8000-000000000003",
      phone: "+998911111111",
      full_name: "Xato Admin",
      role: "platform_admin",
      tenant: null,
    },
  },
};

/** `90 123 45 67` → `998901234567` (serverdagi normallashtirish kabi). */
function normalize(phone) {
  const digits = String(phone ?? "").replace(/\D/g, "");
  return digits.length === 9 ? `998${digits}` : digits;
}

const pretty = (digits) => `+${digits}`;

// --- Ma'lumotnoma ---
const plans = [
  { id: "00000000-0000-7000-8000-0000000000p1", name: "Start", price_tiyin_per_month: 9900000, max_devices: 1, max_users: 3, features: {}, is_active: true, sort: 1, subscribers_count: 4 },
  { id: "00000000-0000-7000-8000-0000000000p2", name: "Biznes", price_tiyin_per_month: 19900000, max_devices: 3, max_users: 10, features: {}, is_active: true, sort: 2, subscribers_count: 3 },
  { id: "00000000-0000-7000-8000-0000000000p3", name: "Eski", price_tiyin_per_month: 5000000, max_devices: 1, max_users: 2, features: {}, is_active: false, sort: 3, subscribers_count: 0 },
];

const tenants = [];
const users = []; // { ...UserBrief, tenant }
const devices = [];
const payments = [];
const events = [];

function addTenant({ name, phone, ownerName, status, paidUntil, trialEndsAt, plan = plans[0], blocked = false, reason = "" }) {
  const id = randomUUID();
  const owner = {
    id: randomUUID(),
    phone: pretty(phone),
    full_name: ownerName,
    role: "owner",
    is_active: true,
    last_login: null,
    created_at: "2026-09-01T09:00:00Z",
    tenant: id,
  };
  users.push(owner);
  accounts[phone] = { password: "ega-parol", user: { ...owner, tenant: { id, name } } };
  tenants.push({
    id,
    name,
    owner_phone: pretty(phone),
    owner_name: ownerName,
    plan: plan.name,
    plan_id: plan.id,
    status,
    paid_until: paidUntil,
    trial_ends_at: trialEndsAt,
    last_activity_at: null,
    is_blocked: blocked,
    created_at: "2026-09-01T09:00:00Z",
    address: "",
    timezone: "Asia/Tashkent",
    default_locale: "uz",
    notes: "",
    blocked_reason: reason,
  });
  return id;
}

const baraka = addTenant({ name: "Baraka do'koni", phone: "998907654321", ownerName: "Do'kon egasi", status: "active", paidUntil: "2026-11-30", trialEndsAt: "2026-09-15" });
addTenant({ name: "Oila market", phone: "998935550011", ownerName: "Olim Karimov", status: "trial", paidUntil: null, trialEndsAt: "2026-10-25", plan: plans[1] });
addTenant({ name: "Yulduz", phone: "998977770022", ownerName: "Zarina", status: "blocked", paidUntil: "2026-08-31", trialEndsAt: "2026-08-01", blocked: true, reason: "To'lov qilinmadi" });

users.push({ id: randomUUID(), phone: null, full_name: "Aziza", role: "cashier", is_active: true, last_login: null, created_at: "2026-09-02T09:00:00Z", tenant: baraka });
devices.push({ id: randomUUID(), tenant: baraka, tenant_name: "Baraka do'koni", code: "D1", name: "Kassa 1", platform: "windows", app_version: "1.0.0", last_sync_at: "2026-10-14T08:00:00Z", last_seen_at: "2026-10-14T08:00:00Z", is_blocked: false, created_at: "2026-09-02T09:00:00Z" });
payments.push(
  { id: randomUUID(), tenant: baraka, tenant_name: "Baraka do'koni", amount_tiyin: 9900000, months: 1, paid_at: "2026-09-15T10:00:00Z", period_from: "2026-09-16", period_to: "2026-10-15", method: "cash", note: "", recorded_by: null, reverses: null },
  { id: randomUUID(), tenant: baraka, tenant_name: "Baraka do'koni", amount_tiyin: 9900000, months: 1, paid_at: "2026-10-10T10:00:00Z", period_from: "2026-10-16", period_to: "2026-11-30", method: "transfer", note: "Click", recorded_by: null, reverses: null },
);
events.push({ id: randomUUID(), tenant: baraka, device: devices[0].id, type: "sale.created", status: "applied", error: null, attempts: 1, client_created_at: "2026-10-14T07:59:00Z", received_at: "2026-10-14T08:00:00Z", applied_at: "2026-10-14T08:00:00Z" });

// --- Statistika (bosh sahifa) ---
const stats = {
  tenants: { total: 12, trial: 3, active: 7, grace: 1, readonly: 1, blocked: 0 },
  mrr_tiyin: 135000000,
  revenue_this_month_tiyin: 45000000,
  expiring_soon: [
    { tenant: "00000000-0000-7000-8000-0000000000b1", name: "Baraka do'koni", paid_until: "2026-10-16", days_left: 1 },
    { tenant: "00000000-0000-7000-8000-0000000000b2", name: "Oila market", paid_until: "2026-10-20", days_left: 5 },
  ],
  stale_devices: 2,
  // 2025-11 … 2026-10.
  monthly_revenue: Array.from({ length: 12 }, (_, i) => {
    const month = ((10 + i) % 12) + 1;
    const year = i < 2 ? 2025 : 2026;
    return {
      month: `${year}-${String(month).padStart(2, "0")}`,
      revenue_tiyin: (10 + i * 3) * 1000000,
    };
  }),
};

// --- Tokenlar ---
let counter = 0;
const sessions = new Map(); // token → telefon

function issue(phone) {
  counter += 1;
  const access = `access-${counter}`;
  const refresh = `refresh-${counter}`;
  sessions.set(access, phone);
  sessions.set(refresh, phone);
  return { access, refresh };
}

/** `Authorization: Bearer access-N` → hisob (yoki `undefined`). */
function accountOf(req) {
  const token = (req.headers.authorization ?? "").replace(/^Bearer /, "");
  const phone = token.startsWith("access-") ? sessions.get(token) : undefined;
  return phone ? { phone, ...accounts[phone] } : undefined;
}

// --- HTTP yordamchilari ---
function send(res, status, body) {
  res.writeHead(status, { "Content-Type": "application/json" });
  res.end(JSON.stringify(body));
}

const fail = (res, status, code, details = {}) => send(res, status, { error: { code, message: code, details } });

async function readJson(req) {
  let raw = "";
  for await (const chunk of req) raw += chunk;
  try {
    return JSON.parse(raw || "{}");
  } catch {
    return {};
  }
}

function page(url, rows, extra = {}) {
  const size = Math.max(1, Number(url.searchParams.get("page_size")) || 50);
  const number = Math.max(1, Number(url.searchParams.get("page")) || 1);
  const start = (number - 1) * size;
  const link = (n) => {
    const next = new URL(url);
    next.searchParams.set("page", String(n));
    return next.toString();
  };
  return {
    count: rows.length,
    next: start + size < rows.length ? link(number + 1) : null,
    previous: number > 1 ? link(number - 1) : null,
    results: rows.slice(start, start + size),
    ...extra,
  };
}

function tenantList(t) {
  return {
    id: t.id,
    name: t.name,
    owner_phone: t.owner_phone,
    owner_name: t.owner_name,
    plan: t.plan,
    status: t.status,
    paid_until: t.paid_until,
    trial_ends_at: t.trial_ends_at,
    devices_count: devices.filter((d) => d.tenant === t.id).length,
    last_activity_at: t.last_activity_at,
    is_blocked: t.is_blocked,
    created_at: t.created_at,
  };
}

function tenantDetail(t) {
  return {
    ...tenantList(t),
    address: t.address,
    timezone: t.timezone,
    default_locale: t.default_locale,
    notes: t.notes,
    blocked_reason: t.blocked_reason,
    subscription: {
      plan: t.plan_id,
      trial_ends_at: t.trial_ends_at,
      paid_until: t.paid_until,
      grace_days: 3,
      offline_days: 7,
      status: t.status,
      days_left: t.status === "trial" ? 10 : t.paid_until ? 46 : null,
    },
    users_count: users.filter((u) => u.tenant === t.id).length,
  };
}

const brief = (u) => ({
  id: u.id,
  phone: u.phone,
  full_name: u.full_name,
  role: u.role,
  is_active: u.is_active,
  last_login: u.last_login,
  created_at: u.created_at,
});

const eventRow = (e) => ({
  id: e.id,
  device: e.device,
  type: e.type,
  status: e.status,
  error: e.error,
  attempts: e.attempts,
  client_created_at: e.client_created_at,
  received_at: e.received_at,
  applied_at: e.applied_at,
});

function tempPassword() {
  return `Tmp-${Math.random().toString(36).slice(2, 8)}`;
}

const invalid = { error: { code: "invalid_credentials", message: "Telefon yoki parol noto'g'ri" } };

createServer(async (req, res) => {
  const url = new URL(req.url ?? "/", `http://127.0.0.1:${port}`);
  const { pathname } = url;
  if (req.method === "GET" && pathname === "/health") return send(res, 200, { ok: true });

  // --- auth ---
  if (req.method === "POST" && pathname === "/api/v1/auth/login/") {
    const { phone, password } = await readJson(req);
    const key = normalize(phone);
    const account = accounts[key];
    if (!account || account.password !== password) return send(res, 401, invalid);
    return send(res, 200, { ...issue(key), user: account.user });
  }

  if (req.method === "POST" && pathname === "/api/v1/auth/refresh/") {
    const { refresh } = await readJson(req);
    const phone = sessions.get(refresh);
    if (!phone || !String(refresh).startsWith("refresh-")) return fail(res, 401, "token_not_valid");
    sessions.delete(refresh);
    return send(res, 200, issue(phone));
  }

  const account = accountOf(req);
  if (req.method === "GET" && pathname === "/api/v1/auth/me/") {
    if (!account) return fail(res, 401, "not_authenticated");
    return send(res, 200, account.user);
  }

  // --- platforma (faqat platform_admin) ---
  if (!pathname.startsWith("/api/v1/platform/")) return fail(res, 404, "not_found");
  if (!account) return fail(res, 401, "not_authenticated");
  if (account.user.role !== "platform_admin") return fail(res, 403, "permission_denied");

  if (req.method === "GET" && pathname === "/api/v1/platform/stats/") {
    if (account.phone === "998911111111") return fail(res, 500, "server_error");
    return send(res, 200, stats);
  }

  if (req.method === "GET" && pathname === "/api/v1/platform/plans/") return send(res, 200, page(url, plans));

  if (pathname === "/api/v1/platform/tenants/") {
    if (req.method === "GET") {
      const search = (url.searchParams.get("search") ?? "").toLowerCase();
      const digits = search.replace(/\D/g, "");
      const status = url.searchParams.get("status");
      const rows = tenants
        .filter((t) => !status || t.status === status)
        .filter(
          (t) =>
            !search ||
            t.name.toLowerCase().includes(search) ||
            (digits.length > 0 && t.owner_phone.replace(/\D/g, "").includes(digits)),
        )
        .sort((a, b) => b.created_at.localeCompare(a.created_at))
        .map(tenantList);
      return send(res, 200, page(url, rows));
    }
    if (req.method === "POST") {
      const body = await readJson(req);
      const details = {};
      if (!body.name?.trim()) details.name = ["required"];
      if (!body.owner?.phone) details.owner = { phone: ["required"] };
      const plan = plans.find((p) => p.id === body.plan && p.is_active);
      if (!plan) details.plan = ["invalid"];
      if (Object.keys(details).length) return fail(res, 400, "validation_error", details);
      const phone = normalize(body.owner.phone);
      if (accounts[phone]) return fail(res, 409, "phone_taken");
      const id = addTenant({
        name: body.name.trim(),
        phone,
        ownerName: body.owner.full_name,
        status: Number(body.trial_days ?? 14) > 0 ? "trial" : "readonly",
        paidUntil: null,
        trialEndsAt: "2026-10-29",
        plan,
      });
      const tenant = tenants.find((t) => t.id === id);
      tenant.created_at = new Date().toISOString();
      tenant.address = body.address ?? "";
      tenant.notes = body.notes ?? "";
      const password = body.owner.password || tempPassword();
      accounts[phone].password = password;
      const owner = users.find((u) => u.tenant === id && u.role === "owner");
      return send(res, 201, {
        tenant: tenantDetail(tenant),
        owner: brief(owner),
        temporary_password: body.owner.password ? null : password,
      });
    }
  }

  const tenantMatch = pathname.match(/^\/api\/v1\/platform\/tenants\/([^/]+)\/(?:([a-z-]+)\/)?$/);
  if (tenantMatch) {
    const [, id, sub] = tenantMatch;
    const tenant = tenants.find((t) => t.id === id);
    if (!tenant) return fail(res, 404, "not_found");
    if (req.method === "GET" && !sub) return send(res, 200, tenantDetail(tenant));
    if (req.method === "POST" && sub === "block") {
      const { reason } = await readJson(req);
      if (!reason?.trim()) return fail(res, 400, "validation_error", { reason: ["required"] });
      Object.assign(tenant, { is_blocked: true, blocked_reason: reason.trim(), status: "blocked" });
      return send(res, 200, tenantDetail(tenant));
    }
    if (req.method === "POST" && sub === "unblock") {
      Object.assign(tenant, { is_blocked: false, blocked_reason: "", status: tenant.paid_until ? "active" : "trial" });
      return send(res, 200, tenantDetail(tenant));
    }
    if (req.method === "GET" && sub === "users") {
      return send(res, 200, page(url, users.filter((u) => u.tenant === id).map(brief)));
    }
    if (req.method === "GET" && sub === "sync-events") {
      return send(res, 200, page(url, events.filter((e) => e.tenant === id).map(eventRow)));
    }
  }

  if (req.method === "GET" && pathname === "/api/v1/platform/devices/") {
    const tenant = url.searchParams.get("tenant");
    return send(res, 200, page(url, devices.filter((d) => !tenant || d.tenant === tenant)));
  }

  if (req.method === "GET" && pathname === "/api/v1/platform/payments/") {
    const tenant = url.searchParams.get("tenant");
    const rows = payments.filter((p) => !tenant || p.tenant === tenant).sort((a, b) => b.paid_at.localeCompare(a.paid_at));
    return send(res, 200, page(url, rows, { total_tiyin: rows.reduce((s, p) => s + p.amount_tiyin, 0) }));
  }

  const resetMatch = pathname.match(/^\/api\/v1\/platform\/users\/([^/]+)\/reset-password\/$/);
  if (req.method === "POST" && resetMatch) {
    const user = users.find((u) => u.id === resetMatch[1]);
    if (!user || !["owner", "manager"].includes(user.role)) return fail(res, 404, "not_found");
    const password = tempPassword();
    const key = normalize(user.phone);
    if (accounts[key]) accounts[key].password = password;
    return send(res, 200, { temporary_password: password });
  }

  fail(res, 404, "not_found");
}).listen(port, "127.0.0.1", () => {
  console.log(`mock api on http://127.0.0.1:${port}`);
});
