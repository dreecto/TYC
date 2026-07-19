// TYC Partner — admin-create-user Edge Function
// ----------------------------------------------------------------------------
// Creates a login account on behalf of a TYC admin and returns a generated
// password to share. Two types:
//   * "partner" — also creates the store (partners row) + a clerk profile
//   * "admin"   — a TYC admin profile attached to TYC HQ
//
// Security: the caller must be a signed-in TYC admin (role='admin'). Account
// creation uses the service-role key, which lives ONLY here on the server —
// never in the app.
//
// Deploy from the Supabase dashboard: Edge Functions -> Deploy a new function
// -> name it exactly "admin-create-user" -> paste this file -> Deploy.
// (SUPABASE_URL / SUPABASE_ANON_KEY / SUPABASE_SERVICE_ROLE_KEY are injected
// automatically — no secrets to set.)
// ----------------------------------------------------------------------------
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });
}

// Readable, unambiguous password like "Kx7p-9mQr-4tYn" (no 0/O/1/l/I).
function generatePassword(): string {
  const chars = "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789";
  const bytes = new Uint8Array(12);
  crypto.getRandomValues(bytes);
  let s = "";
  for (const b of bytes) s += chars[b % chars.length];
  return `${s.slice(0, 4)}-${s.slice(4, 8)}-${s.slice(8, 12)}`;
}

const TYC_HQ_ID = "00000000-0000-0000-0000-000000000001";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return json(405, { error: "Method not allowed." });

  const url = Deno.env.get("SUPABASE_URL")!;
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const authHeader = req.headers.get("Authorization") ?? "";

  // 1) Verify the caller is a signed-in TYC admin.
  const caller = createClient(url, anonKey, {
    global: { headers: { Authorization: authHeader } },
  });
  const { data: userData, error: userErr } = await caller.auth.getUser();
  if (userErr || !userData?.user) return json(401, { error: "Not signed in." });

  const admin = createClient(url, serviceKey);
  const { data: prof } = await admin
    .from("profiles")
    .select("role")
    .eq("id", userData.user.id)
    .single();
  if (!prof || prof.role !== "admin") {
    return json(403, { error: "Admins only." });
  }

  // 2) Parse + validate.
  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return json(400, { error: "Bad request body." });
  }

  const type = body.type === "admin" ? "admin" : "partner";
  const email = String(body.email ?? "").trim().toLowerCase();
  if (!email.includes("@")) {
    return json(400, { error: "A valid email is required." });
  }

  // 3) Create the auth account. Two delivery modes:
  //    * invite === true  -> send an email with a set-your-password link
  //    * otherwise        -> generate a password to share (works with no SMTP)
  const invite = body.invite === true;
  let newId: string;
  let password: string | null = null;

  if (invite) {
    const setPasswordUrl = `${url}/functions/v1/set-password`;
    const { data: invited, error: invErr } = await admin.auth.admin
      .inviteUserByEmail(email, { redirectTo: setPasswordUrl });
    if (invErr || !invited?.user) {
      return json(400, {
        error: invErr?.message ??
          "Could not send the invite. Is email (SMTP) configured?",
      });
    }
    newId = invited.user.id;
  } else {
    password = generatePassword();
    const { data: created, error: createErr } = await admin.auth.admin
      .createUser({ email, password, email_confirm: true });
    if (createErr || !created?.user) {
      return json(400, {
        error: createErr?.message ?? "Could not create the account.",
      });
    }
    newId = created.user.id;
  }

  // 4) Create the profile (+ store for partners). Roll back the auth user on
  //    any failure so we never leave an orphaned login.
  try {
    if (type === "partner") {
      const storeName = String(body.storeName ?? "").trim();
      if (!storeName) throw new Error("Store name is required.");

      const { data: partner, error: pErr } = await admin
        .from("partners")
        .insert({
          name: storeName,
          address: body.address ?? null,
          primary_contact: body.primaryContact ?? null,
          contact_email: email,
          phone: body.phone ?? null,
          payout_rate: 1.0,
          active: true,
        })
        .select("id")
        .single();
      if (pErr || !partner) throw new Error(pErr?.message ?? "Store failed.");

      const { error: profErr } = await admin.from("profiles").insert({
        id: newId,
        partner_id: partner.id,
        full_name: body.primaryContact ?? null,
        role: "clerk",
      });
      if (profErr) throw new Error(profErr.message);
    } else {
      const { error: profErr } = await admin.from("profiles").insert({
        id: newId,
        partner_id: TYC_HQ_ID,
        full_name: body.fullName ?? null,
        role: "admin",
      });
      if (profErr) throw new Error(profErr.message);
    }
  } catch (e) {
    await admin.auth.admin.deleteUser(newId);
    return json(400, { error: e instanceof Error ? e.message : String(e) });
  }

  return json(200, { email, password, type, invited: invite });
});
