// TYC Partner — set-password page
// ----------------------------------------------------------------------------
// The page an invite email links to. It reads the token from the invite link,
// lets the person choose a password, and saves it. After this they open the
// TYC Partner app and sign in with their email + new password.
//
// Deploy from the Supabase dashboard: Edge Functions -> Deploy a new function
// -> name it exactly "set-password" -> paste this file -> Deploy. Then turn
// "Verify JWT" OFF for this function (the browser opens it directly, with no
// auth header). Add its URL to Auth -> URL Configuration -> Redirect URLs:
//   https://<your-project>.supabase.co/functions/v1/set-password
// ----------------------------------------------------------------------------

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, OPTIONS",
};

Deno.serve((req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });

  const url = Deno.env.get("SUPABASE_URL")!;
  const anon = Deno.env.get("SUPABASE_ANON_KEY")!;

  const html = `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Set your password — TYC Partner</title>
<style>
  :root { color-scheme: dark; }
  * { box-sizing: border-box; }
  body { margin:0; background:#0E0E0E; color:#F2F0E8;
    font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",system-ui,sans-serif;
    display:flex; min-height:100vh; align-items:center; justify-content:center; padding:24px; }
  .card { width:100%; max-width:380px; }
  .brand { color:#7ED957; font-weight:800; letter-spacing:.5px; margin-bottom:18px; }
  h1 { font-size:26px; margin:0 0 8px; font-weight:800; }
  p  { color:#9A988F; font-size:14px; line-height:1.45; margin:0 0 18px; }
  label { display:block; font-size:11px; letter-spacing:1.4px; text-transform:uppercase;
    color:#9A988F; margin:16px 0 6px; }
  input { width:100%; padding:14px 16px; border-radius:12px; border:1px solid #2A2A2A;
    background:#1A1A1A; color:#F2F0E8; font-size:16px; }
  input:focus { outline:none; border-color:#7ED957; }
  button { width:100%; margin-top:22px; padding:16px; border:0; border-radius:999px;
    background:#7ED957; color:#07230A; font-size:16px; font-weight:800; cursor:pointer; }
  button:disabled { opacity:.5; cursor:default; }
  .msg { margin-top:16px; font-size:14px; line-height:1.4; }
  .err { color:#E5533C; }
  .ok  { color:#7ED957; }
</style>
</head>
<body>
  <div class="card">
    <div class="brand">TYC PARTNER</div>
    <h1>Set your password</h1>
    <p id="sub">Choose a password for your account, then open the TYC Partner app to sign in.</p>
    <div id="form">
      <label>New password</label>
      <input id="pw" type="password" autocomplete="new-password" placeholder="At least 6 characters">
      <label>Confirm password</label>
      <input id="pw2" type="password" autocomplete="new-password">
      <button id="save">Set password</button>
    </div>
    <div id="msg" class="msg"></div>
  </div>
  <script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>
  <script>
    var client = supabase.createClient("${url}", "${anon}");
    var msg = document.getElementById("msg");
    var form = document.getElementById("form");
    function showErr(t){ msg.className="msg err"; msg.textContent=t; }
    function showOk(t){ msg.className="msg ok"; msg.textContent=t; }

    async function init(){
      try {
        var hash = new URLSearchParams((location.hash || "").replace(/^#/, ""));
        var at = hash.get("access_token");
        var rt = hash.get("refresh_token");
        var code = new URLSearchParams(location.search).get("code");
        if (at) {
          await client.auth.setSession({ access_token: at, refresh_token: rt });
        } else if (code) {
          await client.auth.exchangeCodeForSession(code);
        } else {
          form.style.display = "none";
          showErr("This link is invalid or has expired. Ask your admin to resend the invite.");
        }
      } catch (e) {
        form.style.display = "none";
        showErr("This link is invalid or has expired. Ask your admin to resend the invite.");
      }
    }

    document.getElementById("save").onclick = async function(){
      var pw = document.getElementById("pw").value;
      var pw2 = document.getElementById("pw2").value;
      if (pw.length < 6) { showErr("Password must be at least 6 characters."); return; }
      if (pw !== pw2) { showErr("Passwords do not match."); return; }
      this.disabled = true; showOk("Saving…");
      var res = await client.auth.updateUser({ password: pw });
      if (res.error) { this.disabled = false; showErr(res.error.message); return; }
      form.style.display = "none";
      showOk("Password set. Open the TYC Partner app and sign in with your email and new password.");
    };

    init();
  </script>
</body>
</html>`;

  return new Response(html, {
    headers: { ...cors, "Content-Type": "text/html; charset=utf-8" },
  });
});
