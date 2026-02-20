import http from "node:http";
import { URL } from "node:url";

const PORT = Number(process.env.PORT ?? 3000);
const COZE_BASE_URL = "https://api.coze.cn/v3/chat";

function setCorsHeaders(req, res) {
  const configuredOrigin = process.env.ALLOWED_ORIGIN;
  const requestOrigin = req.headers.origin;
  const allowOrigin = configuredOrigin ?? requestOrigin ?? "*";

  res.setHeader("Access-Control-Allow-Origin", allowOrigin);
  res.setHeader("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type, Authorization");
}

function sendJson(res, statusCode, payload) {
  res.statusCode = statusCode;
  res.setHeader("Content-Type", "application/json; charset=utf-8");
  res.end(JSON.stringify(payload));
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

async function readJsonBody(req) {
  const chunks = [];
  for await (const chunk of req) {
    chunks.push(chunk);
  }

  if (chunks.length === 0) return {};
  const raw = Buffer.concat(chunks).toString("utf-8");
  return JSON.parse(raw);
}

const server = http.createServer(async (req, res) => {
  setCorsHeaders(req, res);

  const url = new URL(req.url ?? "/", `http://localhost:${PORT}`);

  if (req.method === "OPTIONS") {
    res.statusCode = 200;
    res.end();
    return;
  }

  if (url.pathname === "/api/debug-env") {
    const pat = process.env.COZE_PAT;
    const botId = process.env.COZE_BOT_ID;
    sendJson(res, 200, {
      COZE_PAT: pat ? `Present (length: ${pat.length}, starts with: ${pat.substring(0, 5)}...)` : "Missing",
      COZE_BOT_ID: botId ? `Present (length: ${botId.length})` : "Missing",
      PORT: process.env.PORT,
      NODE_ENV: process.env.NODE_ENV,
      Limit: "Fixed for debugging"
   });
   return;
  }

  if (url.pathname !== "/api/coze-chat") {
    sendJson(res, 404, { error: "Not found" });
    return;
  }

  if (req.method !== "POST") {
    sendJson(res, 405, { error: "Method not allowed" });
    return;
  }

  const cozePat = process.env.COZE_PAT;
  const cozeBotId = process.env.COZE_BOT_ID;

  if (!cozePat || !cozeBotId) {
    sendJson(res, 500, { error: "Missing COZE_PAT or COZE_BOT_ID in .env" });
    return;
  }

  try {
    const body = await readJsonBody(req);
    const query = body?.query;
    const userId = body?.userId ?? "user_flutter_app";

    if (typeof query !== "string" || query.trim().length === 0) {
      sendJson(res, 400, { error: "query is required" });
      return;
    }

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
          {
            role: "user",
            content: query,
            content_type: "text",
          },
        ],
      }),
    });

    if (!createResp.ok) {
      const raw = await createResp.text();
      sendJson(res, createResp.status, { error: `Create chat failed: ${raw}` });
      return;
    }

    const createData = await createResp.json();
    const chatId = createData?.data?.id;
    const conversationId = createData?.data?.conversation_id;

    if (!chatId || !conversationId) {
      sendJson(res, 500, { error: "Invalid create chat response" });
      return;
    }

    let status = "in_progress";
    for (let i = 0; i < 90; i += 1) {
      if (status !== "in_progress" && status !== "created") break;

      await new Promise((resolve) => setTimeout(resolve, 1000));
      const pollResp = await fetch(
        `${COZE_BASE_URL}/retrieve?chat_id=${chatId}&conversation_id=${conversationId}`,
        {
          headers: {
            Authorization: `Bearer ${cozePat}`,
          },
        },
      );

      if (!pollResp.ok) {
        const raw = await pollResp.text();
        sendJson(res, pollResp.status, { error: `Poll failed: ${raw}` });
        return;
      }

      const pollData = await pollResp.json();
      status = pollData?.data?.status ?? "failed";

      if (status === "failed" || status === "requires_action") {
        sendJson(res, 500, { error: `Chat stopped with status: ${status}` });
        return;
      }
    }

    if (status === "in_progress" || status === "created") {
      sendJson(res, 504, {
        error: "Chat timed out before completion. Please retry once.",
      });
      return;
    }

    const msgResp = await fetch(
      `https://api.coze.cn/v3/chat/message/list?chat_id=${chatId}&conversation_id=${conversationId}`,
      {
        headers: {
          Authorization: `Bearer ${cozePat}`,
        },
      },
    );

    if (!msgResp.ok) {
      const raw = await msgResp.text();
      sendJson(res, msgResp.status, { error: `Message list failed: ${raw}` });
      return;
    }

    const msgData = await msgResp.json();
    const content = getMessageContent(msgData?.data);
    sendJson(res, 200, { content });
  } catch (error) {
    sendJson(res, 500, { error: `Server error: ${String(error)}` });
  }
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`Local proxy server running at http://0.0.0.0:${PORT}`);
});
