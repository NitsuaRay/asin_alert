import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";
import * as jose from "npm:jose@5";

// Helper function to get Google OAuth2 Access Token for FCM HTTP v1 API
async function getAccessToken(serviceAccount: any): Promise<string> {
  // Fix escaped newlines in private key if set via Supabase Secrets CLI/UI
  const formattedPrivateKey = serviceAccount.private_key.replace(/\\n/g, "\n");

  // Import the RSA private key from Firebase Service Account
  const privateKey = await jose.importPKCS8(formattedPrivateKey, "RS256");

  // Generate OAuth2 Assertion JWT
  const jwt = await new jose.SignJWT({})
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
  try {
    const payload = await req.json();
    const record = payload.record; // Newly inserted emergency row

    if (!record) {
      return new Response(JSON.stringify({ error: "No record found in payload" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    // Parse Firebase Service Account Key stored in Supabase Secret
    const serviceAccountRaw = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");
    if (!serviceAccountRaw) {
      throw new Error("FIREBASE_SERVICE_ACCOUNT secret is missing");
    }
    const serviceAccount = JSON.parse(serviceAccountRaw);

    // 1. Initialize Supabase Admin Client
    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    // 2. Fetch establishment business profile details
    const { data: establishment } = await supabaseAdmin
      .from("profiles")
      .select("full_name, address, barangay, phone_number")
      .eq("id", record.establishment_id)
      .single();

    const businessName = establishment?.full_name || "Establishment";
    const address = establishment?.address || "Asingan";
    const isSilent = record.notes?.includes("SILENT") ?? false;

    // 3. Fetch all active Police Officer FCM tokens from responder_tokens
    const { data: tokens, error: tokenError } = await supabaseAdmin
      .from("responder_tokens")
      .select("fcm_token");

    if (tokenError || !tokens || tokens.length === 0) {
      console.log("No active police responder tokens found in DB.");
      return new Response(
        JSON.stringify({ message: "No active police tokens found." }),
        { status: 200, headers: { "Content-Type": "application/json" } }
      );
    }

    const fcmTokens = tokens.map((t) => t.fcm_token).filter(Boolean);

    // 4. Get FCM OAuth2 Access Token
    const accessToken = await getAccessToken(serviceAccount);

    // 5. Send High-Priority FCM Push Notification to all police responders
    const notificationPromises = fcmTokens.map(async (fcmToken) => {
      const title = isSilent
        ? `🤫 SILENT PANIC ALARM: ${businessName}`
        : `🚨 EMERGENCY ALERT: ${record.category.toUpperCase()}`;

      const body = `${businessName} in ${address} has triggered an urgent alert!`;

      const fcmPayload = {
        message: {
          token: fcmToken,
          notification: {
            title: title,
            body: body,
          },
          data: {
            emergency_id: String(record.id),
            category: String(record.category),
            latitude: String(record.latitude),
            longitude: String(record.longitude),
            is_silent: String(isSilent),
            click_action: "FLUTTER_NOTIFICATION_CLICK",
          },
          android: {
            priority: "HIGH", // Forces Android to wake device and show heads-up banner
            notification: {
              channel_id: "siren_channel", // Must match AndroidNotificationChannel in Flutter
              sound: "siren", // References android/app/src/main/res/raw/siren.mp3
              priority: "MAX",
              visibility: "PUBLIC",
            },
          },
          apns: {
            payload: {
              aps: {
                alert: { title, body },
                sound: "siren.caf",
                "content-available": 1,
              },
            },
          },
        },
      };

      try {
        const response = await fetch(
          `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`,
          {
            method: "POST",
            headers: {
              Authorization: `Bearer ${accessToken}`,
              "Content-Type": "application/json",
            },
            body: JSON.stringify(fcmPayload),
          }
        );
        const resData = await response.json();
        return { success: response.ok, resData };
      } catch (err) {
        console.error(`Error sending push to token ${fcmToken}:`, err);
        return { success: false, error: err };
      }
    });

    const results = await Promise.all(notificationPromises);

    return new Response(
      JSON.stringify({ success: true, count: fcmTokens.length, results }),
      { headers: { "Content-Type": "application/json" } }
    );
  } catch (error: any) {
    console.error("Edge Function Error:", error);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});