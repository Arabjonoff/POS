// E2E uchun soxta Django API (faqat auth endpointlari). Haqiqiy backend
// kontrakti: docs/specs/auth-roles.md. Ishga tushirish: `node e2e/mock-api.mjs`.
import { createServer } from "node:http";

const port = Number(process.env.E2E_API_PORT ?? 3199);

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
  "998907654321": {
    password: "ega-parol",
    user: {
      id: "00000000-0000-7000-8000-000000000002",
      phone: "+998907654321",
      full_name: "Do'kon egasi",
      role: "owner",
      tenant: { id: "00000000-0000-7000-8000-0000000000aa", name: "Mahalla do'koni" },
    },
  },
};

/** `90 123 45 67` → `998901234567` (serverdagi normallashtirish kabi). */
function normalize(phone) {
  const digits = String(phone ?? "").replace(/\D/g, "");
  return digits.length === 9 ? `998${digits}` : digits;
}

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

function send(res, status, body) {
  res.writeHead(status, { "Content-Type": "application/json" });
  res.end(JSON.stringify(body));
}

async function readJson(req) {
  let raw = "";
  for await (const chunk of req) raw += chunk;
  try {
    return JSON.parse(raw || "{}");
  } catch {
    return {};
  }
}

const invalid = { error: { code: "invalid_credentials", message: "Telefon yoki parol noto'g'ri" } };

createServer(async (req, res) => {
  const url = new URL(req.url ?? "/", `http://127.0.0.1:${port}`);
  if (req.method === "GET" && url.pathname === "/health") return send(res, 200, { ok: true });

  if (req.method === "POST" && url.pathname === "/api/v1/auth/login/") {
    const { phone, password } = await readJson(req);
    const key = normalize(phone);
    const account = accounts[key];
    if (!account || account.password !== password) return send(res, 401, invalid);
    return send(res, 200, { ...issue(key), user: account.user });
  }

  if (req.method === "POST" && url.pathname === "/api/v1/auth/refresh/") {
    const { refresh } = await readJson(req);
    const phone = sessions.get(refresh);
    if (!phone || !String(refresh).startsWith("refresh-")) {
      return send(res, 401, { error: { code: "token_not_valid" } });
    }
    sessions.delete(refresh);
    return send(res, 200, issue(phone));
  }

  if (req.method === "GET" && url.pathname === "/api/v1/auth/me/") {
    const token = (req.headers.authorization ?? "").replace(/^Bearer /, "");
    const phone = token.startsWith("access-") ? sessions.get(token) : undefined;
    if (!phone) return send(res, 401, { error: { code: "not_authenticated" } });
    return send(res, 200, accounts[phone].user);
  }

  send(res, 404, { error: { code: "not_found" } });
}).listen(port, "127.0.0.1", () => {
  console.log(`mock api on http://127.0.0.1:${port}`);
});
