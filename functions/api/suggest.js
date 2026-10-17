const providerUrl = "https://api.kedy.dev/v1/chat/completions";

function jsonResponse(body, status) {
  return Response.json(body, {
    status,
    headers: { "Cache-Control": "no-store" },
  });
}

export async function onRequestPost({ request, env }) {
  if (!env.KEDY_API_KEY) {
    return jsonResponse(
      { detail: "AI servisi sunucuda yapılandırılmamış." },
      503,
    );
  }

  if (Number(request.headers.get("content-length") || 0) > 10_000) {
    return jsonResponse({ detail: "İstek boyutu çok büyük." }, 413);
  }

  let payload;
  try {
    payload = await request.json();
  } catch {
    return jsonResponse({ detail: "Geçersiz JSON isteği." }, 400);
  }

  if (
    !payload ||
    typeof payload.message !== "string" ||
    payload.message.trim().length === 0 ||
    payload.message.length > 2_000
  ) {
    return jsonResponse(
      { detail: "Mesaj boş olamaz ve 2000 karakteri aşamaz." },
      400,
    );
  }

  let providerResponse;
  try {
    providerResponse = await fetch(providerUrl, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${env.KEDY_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: "novaq",
        messages: [{ role: "user", content: payload.message.trim() }],
      }),
      signal: AbortSignal.timeout(45_000),
    });
  } catch (error) {
    const timedOut = error instanceof Error && error.name === "TimeoutError";
    return jsonResponse(
      {
        detail: timedOut
          ? "AI servisi zaman aşımına uğradı."
          : "AI servisine bağlanılamadı.",
      },
      timedOut ? 504 : 502,
    );
  }

  if (!providerResponse.ok) {
    return jsonResponse(
      { detail: "AI sağlayıcısı isteği tamamlayamadı." },
      502,
    );
  }

  let result;
  try {
    result = await providerResponse.json();
  } catch {
    return jsonResponse(
      { detail: "AI sağlayıcısından geçersiz yanıt geldi." },
      502,
    );
  }

  if (
    typeof result?.choices?.[0]?.message?.content !== "string" ||
    result.choices[0].message.content.trim().length === 0
  ) {
    return jsonResponse(
      { detail: "AI sağlayıcısından geçersiz yanıt geldi." },
      502,
    );
  }

  return jsonResponse(result, 200);
}

export async function onRequest({ request }) {
  if (request.method !== "POST") {
    return jsonResponse(
      { detail: "Bu uç nokta yalnızca POST kabul eder." },
      405,
    );
  }
}
