import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import * as jose from "https://deno.land/x/jose@v4.14.4/index.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// Helper function to get Google OAuth2 Access Token for FCM HTTP v1 API
async function getAccessToken(serviceAccount: any): Promise<string> {
  const formattedPrivateKey = serviceAccount.private_key.replace(/\\n/g, "\n");

  const privateKey = await jose.importPKCS8(formattedPrivateKey, "RS256");

  // Generate OAuth2 Assertion JWT with FCM Scope
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

  // Request Access Token from Google
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
  // Handle CORS preflight request
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const payload = await req.json();
    const record = payload.record || payload.new || {};

    // 1. Fetch FIREBASE_SERVICE_ACCOUNT secret
    const serviceAccountRaw = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");
    if (!serviceAccountRaw) {
      throw new Error("FIREBASE_SERVICE_ACCOUNT secret is missing");
    }

    const serviceAccount = JSON.parse(serviceAccountRaw);
    const accessToken = await getAccessToken(serviceAccount);

    // 2. Fetch active responder tokens from database
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

    // 3. Format Notification Title & Message based on status
    const category = record?.category?.toUpperCase() || "POLICE";
    const status = record?.status || "pending";

    let title = "🚨 EMERGENCY PANIC ALERT!";
    let body = `New ${category} alert triggered! Tap to inspect.`;

    if (status === "acknowledged") {
      title = "👮 Alert Acknowledged";
      body = "Responders acknowledged the emergency alert!";
    } else if (status === "en_route") {
      title = "🚔 Officers En Route";
      body = "A police unit is now heading to the scene!";
    } else if (status === "resolved") {
      title = "✅ Emergency Resolved";
      body = "The incident has been marked as resolved.";
    }

    // 4. Send FCM Push Notification to all active responder phones
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
                  channel_id: "siren_channel_v3",
                  sound: "siren",
                },
              },
              apns: {
                payload: {
                  aps: {
                    sound: "siren.aiff",
                    contentAvailable: true,
                  },
                },
              },
              data: {
                emergency_id: String(record?.id || ""),
                status: status,
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