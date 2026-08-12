import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";
import * as jose from "npm:jose@5";

// Helper function to get Google OAuth2 Access Token for FCM HTTP v1 API
async function getAccessToken(serviceAccount: any): Promise<string> {
  // Import the RSA private key from Firebase Service Account
  const privateKey = await jose.importPKCS8(
    serviceAccount.private_key,
    "RS256"
  );

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
  return data.access_token;
}

serve(async (req) => {
  try {
    const payload = await req.json();
    const record = payload.record; // Newly inserted emergency row from Database Webhook

    if (!record) {
      return new Response(JSON.stringify({ error: "No record found" }), { status: 400 });
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

    const businessName = establishment?.full_name || "Unknown Business";
    const address = establishment?.address || "Asingan";

    // 3. Fetch all active Police Officer FCM tokens from responder_tokens
    const { data: tokens, error: tokenError } = await supabaseAdmin
      .from("responder_tokens")
      .select("fcm_token");

    if (tokenError || !tokens || tokens.length === 0) {
      return new Response(JSON.stringify({ message: "No active police tokens found." }), { status: 200 });
    }

    const fcmTokens = tokens.map((t) => t.fcm_token);

    // 4. Get FCM OAuth2 Access Token
    const accessToken = await getAccessToken(serviceAccount);

    // 5. Send FCM High-Priority Push Notification to all police responders
    const notificationPromises = fcmTokens.map(async (fcmToken) => {
      const fcmPayload = {
        message: {
          token: fcmToken,
          notification: {
            title: `🚨 EMERGENCY ALERT: ${record.category.toUpperCase()}`,
            body: `${businessName} in ${address} has triggered an urgent alert!`,
          },
          data: {
            emergency_id: record.id,
            category: record.category,
            latitude: String(record.latitude),
            longitude: String(record.longitude),
            click_action: "FLUTTER_NOTIFICATION_CLICK",
          },
          android: {
            priority: "HIGH",
            notification: {
              sound: "siren", // Plays android/app/src/main/res/raw/siren.mp3
              channel_id: "siren_channel",
              priority: "MAX",
              visibility: "PUBLIC",
            },
          },
        },
      };

      return fetch(
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
    });

    await Promise.all(notificationPromises);

    return new Response(
      JSON.stringify({ success: true, count: fcmTokens.length }),
      { headers: { "Content-Type": "application/json" } }
    );
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), { status: 500 });
  }
});