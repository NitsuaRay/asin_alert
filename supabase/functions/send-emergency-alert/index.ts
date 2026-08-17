import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import * as jose from "https://deno.land/x/jose@v4.14.4/index.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

async function getAccessToken(serviceAccount: any): Promise<string> {
  const formattedPrivateKey = serviceAccount.private_key.replace(/\\n/g, "\n");
  const privateKey = await jose.importPKCS8(formattedPrivateKey, "RS256");

  const jwt = await new jose.SignJWT({
    scope: "https://www.googleapis.com/auth/firebase.messaging",
  })
    .setProtectedHeader({ alg: "RS256", typ: "JWT" })
    .setIssuer(serviceAccount.client_email)
    .setSubject(serviceAccount.client_email)
    .setAudience("https://oauth2.googleapis.com/token")
    .setExpirationTime("1h")
    .setIssuedAt()
    .sign(privateKey);

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });

  const data = await res.json();
  if (!res.ok) {
    throw new Error(`OAuth2 Token Error: ${JSON.stringify(data)}`);
  }
  return data.access_token;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const payload = await req.json();
    const record = payload.record || payload.new || {};

    const serviceAccountRaw = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");
    if (!serviceAccountRaw) {
      throw new Error("FIREBASE_SERVICE_ACCOUNT secret is missing");
    }

    const serviceAccount = JSON.parse(serviceAccountRaw);
    const accessToken = await getAccessToken(serviceAccount);

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    const tokensRes = await fetch(`${supabaseUrl}/rest/v1/responder_tokens?select=fcm_token`, {
      headers: {
        "apikey": supabaseServiceKey!,
        "Authorization": `Bearer ${supabaseServiceKey}`,
      },
    });

    const tokenRows = await tokensRes.json();
    if (!Array.isArray(tokenRows) || tokenRows.length === 0) {
      return new Response(JSON.stringify({ message: "No responder tokens found" }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      });
    }

    const isSilent = record?.is_silent === true || record?.is_silent === "true";
    const category = record?.category?.toUpperCase() || "POLICE";
    const status = record?.status || "pending";

    let title = isSilent ? "🤫 SILENT PANIC ALERT!" : "🚨 EMERGENCY PANIC ALERT!";
    let body = isSilent
      ? `Discreet ${category} alert triggered! Tap to inspect.`
      : `New ${category} alert triggered! Tap to inspect.`;

    if (status === "acknowledged") {
      title = isSilent ? "🤫 Alert Acknowledged" : "👮 Alert Acknowledged";
      body = "Responders acknowledged the emergency alert!";
    } else if (status === "en_route") {
      title = isSilent ? "🤫 Officers En Route" : "🚔 Officers En Route";
      body = "A police unit is now heading to the scene!";
    } else if (status === "resolved") {
      title = "✅ Emergency Resolved";
      body = "The incident has been marked as resolved.";
    }

    const sendPromises = tokenRows.map(async (row: { fcm_token: string }) => {
      return fetch(
        `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`,
        {
          method: "POST",
          headers: {
            "Authorization": `Bearer ${accessToken}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            message: {
              token: row.fcm_token,
              notification: {
                title: title,
                body: body,
              },
              android: {
                priority: "high",
                notification: {
                  channel_id: isSilent ? "silent_alert_channel_v2" : "vibration_alert_channel_v1",
                },
              },
              apns: {
                payload: {
                  aps: {
                    contentAvailable: true,
                  },
                },
              },
              data: {
                emergency_id: String(record?.id || ""),
                status: status,
                is_silent: String(isSilent),
                title: title,
                body: body,
              },
            },
          }),
        }
      );
    });

    await Promise.all(sendPromises);

    return new Response(JSON.stringify({ success: true, count: tokenRows.length }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 200,
    });
  } catch (err: any) {
    return new Response(JSON.stringify({ error: err.message }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 400,
    });
  }
});