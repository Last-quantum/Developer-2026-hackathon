import type { VercelRequest, VercelResponse } from "@vercel/node";

const COZE_BASE_URL = "https://api.coze.cn/v3/chat";

function setCorsHeaders(req: VercelRequest, res: VercelResponse) {
  const configuredOrigin = process.env.ALLOWED_ORIGIN;
  const requestOrigin = req.headers.origin;
  const allowOrigin = configuredOrigin ?? requestOrigin ?? "*";

  res.setHeader("Access-Control-Allow-Origin", allowOrigin);
  res.setHeader("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type, Authorization");
}

function getMessageContent(messages: unknown): string {
  if (!Array.isArray(messages)) return "No response from AI";

  const normalized = messages
    .filter(
      (m): m is { type?: unknown; role?: unknown; content?: unknown } =>
        typeof m === "object" && m !== null,
    )
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

export default async function handler(req: VercelRequest, res: VercelResponse) {
  setCorsHeaders(req, res);

  if (req.method === "OPTIONS") {
    return res.status(200).end();
  }

  if (req.method !== "POST") {
    return res.status(405).json({ error: "Method not allowed" });
  }

  const cozePat = process.env.COZE_PAT;
  const cozeBotId = process.env.COZE_BOT_ID;

  if (!cozePat || !cozeBotId) {
    return res
      .status(500)
      .json({ error: "Missing COZE_PAT or COZE_BOT_ID in server env" });
  }

  const query = req.body?.query;
  const userId = req.body?.userId ?? "user_flutter_app";

  if (typeof query !== "string" || query.trim().length === 0) {
    return res.status(400).json({ error: "query is required" });
  }

  try {
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
      return res
        .status(createResp.status)
        .json({ error: `Create chat failed: ${raw}` });
    }

    const createData = (await createResp.json()) as {
      data?: { id?: string; conversation_id?: string };
    };

    const chatId = createData.data?.id;
    const conversationId = createData.data?.conversation_id;

    if (!chatId || !conversationId) {
      return res.status(500).json({ error: "Invalid create chat response" });
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
        return res
          .status(pollResp.status)
          .json({ error: `Poll failed: ${raw}` });
      }

      const pollData = (await pollResp.json()) as {
        data?: { status?: string };
      };
      status = pollData.data?.status ?? "failed";

      if (status === "failed" || status === "requires_action") {
        return res
          .status(500)
          .json({ error: `Chat stopped with status: ${status}` });
      }
    }

    if (status === "in_progress" || status === "created") {
      return res.status(504).json({
        error: "Chat timed out before completion. Please retry once.",
      });
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
      return res
        .status(msgResp.status)
        .json({ error: `Message list failed: ${raw}` });
    }

    const msgData = (await msgResp.json()) as { data?: unknown };
    const content = getMessageContent(msgData.data);
    return res.status(200).json({ content });
  } catch (error) {
    return res.status(500).json({ error: `Server error: ${String(error)}` });
  }
}
