const COZE_BASE_URL = "https://api.coze.cn/v3/chat";

function corsHeaders(origin) {
  return {
    "Access-Control-Allow-Origin": origin || "*",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type, Authorization",
  };
}

function jsonResponse(data, status = 200, origin) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json", ...corsHeaders(origin) },
  });
}

function getMessageContent(messages) {
  if (!Array.isArray(messages)) return "No response from AI";

  const normalized = messages
    .filter((m) => m && typeof m === "object")
    .map((m) => ({
      type: m.type,
      role: m.role,
      content: typeof m.content === "string" ? m.content.trim() : "",
    }))
    .filter((m) => m.content.length > 0);

  if (normalized.length === 0) return "No response from AI";

  const byType = [...normalized].reverse().find((m) => m.type === "answer");
  if (byType) return byType.content;

  const byRole = [...normalized].reverse().find((m) => m.role === "assistant");
  if (byRole) return byRole.content;

  return normalized.at(-1)?.content ?? "No response from AI";
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

export default {
  async fetch(request, env) {
    const origin = request.headers.get("Origin") || "*";

    if (request.method === "OPTIONS") {
      return new Response(null, { status: 200, headers: corsHeaders(origin) });
    }

    const url = new URL(request.url);
    if (url.pathname !== "/api/coze-chat") {
      return jsonResponse({ error: "Not found" }, 404, origin);
    }

    if (request.method !== "POST") {
      return jsonResponse({ error: "Method not allowed" }, 405, origin);
    }

    const cozePat = env.COZE_PAT;
    const cozeBotId = env.COZE_BOT_ID;

    if (!cozePat || !cozeBotId) {
      return jsonResponse(
        { error: "Missing COZE_PAT or COZE_BOT_ID" },
        500,
        origin
      );
    }

    try {
      const body = await request.json();
      const query = body?.query;
      const userId = body?.userId ?? "user_flutter_app";

      if (typeof query !== "string" || query.trim().length === 0) {
        return jsonResponse({ error: "query is required" }, 400, origin);
      }

      // 1. Create chat
      const createResp = await fetch(COZE_BASE_URL, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${cozePat}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          bot_id: cozeBotId,
          user_id: userId,
          stream: false,
          additional_messages: [
            { role: "user", content: query, content_type: "text" },
          ],
        }),
      });

      if (!createResp.ok) {
        const raw = await createResp.text();
        return jsonResponse(
          { error: `Create chat failed: ${raw}` },
          createResp.status,
          origin
        );
      }

      const createData = await createResp.json();
      const chatId = createData?.data?.id;
      const conversationId = createData?.data?.conversation_id;

      if (!chatId || !conversationId) {
        return jsonResponse(
          { error: "Invalid create chat response" },
          500,
          origin
        );
      }

      // 2. Poll for completion (max 25 attempts = 25 seconds)
      let status = "in_progress";
      for (let i = 0; i < 25; i++) {
        if (status !== "in_progress" && status !== "created") break;

        await sleep(1000);
        const pollResp = await fetch(
          `${COZE_BASE_URL}/retrieve?chat_id=${chatId}&conversation_id=${conversationId}`,
          { headers: { Authorization: `Bearer ${cozePat}` } }
        );

        if (!pollResp.ok) {
          const raw = await pollResp.text();
          return jsonResponse(
            { error: `Poll failed: ${raw}` },
            pollResp.status,
            origin
          );
        }

        const pollData = await pollResp.json();
        status = pollData?.data?.status ?? "failed";

        if (status === "failed" || status === "requires_action") {
          return jsonResponse(
            { error: `Chat stopped with status: ${status}` },
            500,
            origin
          );
        }
      }

      if (status === "in_progress" || status === "created") {
        return jsonResponse(
          { error: "Chat timed out. Please retry." },
          504,
          origin
        );
      }

      // 3. Get messages
      const msgResp = await fetch(
        `https://api.coze.cn/v3/chat/message/list?chat_id=${chatId}&conversation_id=${conversationId}`,
        { headers: { Authorization: `Bearer ${cozePat}` } }
      );

      if (!msgResp.ok) {
        const raw = await msgResp.text();
        return jsonResponse(
          { error: `Message list failed: ${raw}` },
          msgResp.status,
          origin
        );
      }

      const msgData = await msgResp.json();
      const content = getMessageContent(msgData?.data);
      return jsonResponse({ content }, 200, origin);
    } catch (error) {
      return jsonResponse(
        { error: `Server error: ${String(error)}` },
        500,
        origin
      );
    }
  },
};
