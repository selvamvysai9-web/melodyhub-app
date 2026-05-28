// ============================================
// Cloudflare Worker — Melody Hub AI + Search Gateway
// ============================================
// Deploy at: https://dash.cloudflare.com -> Workers & Pages -> Create Worker
// Name: melody-hub-ai
// Set GEMINI_API_KEY and YOUTUBE_API_KEY in Settings > Variables and Secrets

export default {
  async fetch(request, env) {
    if (request.method === "OPTIONS") {
      return new Response(null, {
        headers: {
          "Access-Control-Allow-Origin": "*",
          "Access-Control-Allow-Methods": "POST, OPTIONS",
          "Access-Control-Allow-Headers": "Content-Type",
        },
      });
    }

    if (request.method !== "POST") {
      return new Response("Only POST requests allowed", { status: 405 });
    }

    try {

      const body = await request.json();
      const mode = body.mode || "chat";

      // ── Search mode: proxy YouTube search ──────────────────────────
      if (mode === "search") {
        const query = body.query;
        if (!query || typeof query !== "string") {
          return new Response(
            JSON.stringify({ error: "Missing 'query' in request body" }),
            { status: 400, headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" } }
          );
        }

        if (!env.YOUTUBE_API_KEY) {
          return new Response(
            JSON.stringify({ error: "YOUTUBE_API_KEY not configured" }),
            { status: 500, headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" } }
          );
        }

        const params = new URLSearchParams({
          part: "snippet",
          maxResults: String(body.maxResults || 15),
          q: query,
          type: "video",
          videoCategoryId: "10",
          key: env.YOUTUBE_API_KEY,
        });

        const ytResponse = await fetch(
          `https://www.googleapis.com/youtube/v3/search?${params.toString()}`
        );

        if (!ytResponse.ok) {
          return new Response(
            JSON.stringify({ error: "YouTube API error" }),
            { status: ytResponse.status, headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" } }
          );
        }

        const ytData = await ytResponse.json();
        const items = ytData.items || [];

        const results = items.map((item) => {
          const snippet = item.snippet || {};
          const id = item.id || {};
          const thumbnails = snippet.thumbnails || {};
          return {
            videoId: id.videoId || "",
            title: snippet.title || "Unknown",
            artist: snippet.channelTitle || "Unknown",
            thumbnail: (thumbnails.high || thumbnails.medium || thumbnails.default || {}).url || "",
          };
        });

        return new Response(JSON.stringify({ results }), {
          headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
        });
      }

      // ── Gemini-powered modes ───────────────────────────────────────
      const prompt = body.prompt;
      if (!prompt || typeof prompt !== "string") {
        return new Response(
          JSON.stringify({ error: "Missing 'prompt' in request body" }),
          { status: 400, headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" } }
        );
      }

      let systemInstruction = "";
      let generationConfig = {};

      if (mode === "mood") {
        systemInstruction = `You are a music mood analyzer. Analyze the user's message and return ONLY valid JSON with these exact fields:
{"mood": "chill|energetic|dark|euphoric|neutral", "rationale": "brief explanation", "primary_hex": "#RRGGBB", "secondary_hex": "#RRGGBB"}
Do not include any text outside the JSON object.`;
        generationConfig = { responseMimeType: "application/json" };
      } else if (mode === "enrich") {
        systemInstruction = `You are a music metadata enricher. Given a song title and artist, return ONLY valid JSON with these fields:
{"lyrics": "full lyrics or empty string", "genre": "primary genre", "mood": "chill|energetic|dark|euphoric|neutral", "year": 2024, "tags": ["tag1","tag2"]}
If you cannot find lyrics, return an empty string for that field. Do not include any text outside the JSON object.`;
        generationConfig = { responseMimeType: "application/json" };
      } else if (mode === "discover") {
        const recent = Array.isArray(body.recently_played) ? body.recently_played : [];
        const recentBlock =
          recent.length > 0
            ? recent.map((t, i) => `${i + 1}. ${t}`).join("\n")
            : "No listening history yet.";
        systemInstruction = `You are a music discovery engine for Melody Hub (like Spotify Discover Weekly).
Given the user's recently played tracks below, suggest exactly 10 NEW songs they would enjoy.
Rules:
- Do NOT repeat any song from the recently played list.
- Use real, well-known songs likely available on YouTube.
- Mix genres intelligently based on their taste.
- Return ONLY valid JSON with this exact shape:
{"playlist_title":"short catchy title","summary":"one sentence vibe","tracks":[{"title":"Song","artist":"Artist","reason":"brief why"}]}
Recently played:
${recentBlock}`;
        generationConfig = { responseMimeType: "application/json" };
      } else {
        systemInstruction = `You are SonicAI, a music intelligence assistant for the Melody Hub app. Keep responses concise (max 3 short paragraphs). Use markdown for formatting. You can recommend songs, suggest playlists, analyze music preferences, and discuss genres.`;
      }

      const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${env.GEMINI_API_KEY}`;

      const requestBody = {
        contents: [{ parts: [{ text: prompt }] }],
        systemInstruction: { parts: [{ text: systemInstruction }] },
      };

      if (Object.keys(generationConfig).length > 0) {
        requestBody.generationConfig = generationConfig;
      }

      const geminiResponse = await fetch(geminiUrl, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(requestBody),
      });

      if (!geminiResponse.ok) {
        const errorText = await geminiResponse.text();
        console.error("Gemini API Error:", errorText);
        return new Response(
          JSON.stringify({ error: "Error communicating with Gemini AI" }),
          { status: 500, headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" } }
        );
      }

      const data = await geminiResponse.json();
      const aiResponse = data.candidates?.[0]?.content?.parts?.[0]?.text || "";

      if (mode === "mood" || mode === "enrich" || mode === "discover") {
        try {
          const parsed = JSON.parse(aiResponse);
          return new Response(JSON.stringify(parsed), {
            headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
          });
        } catch (_) {
          return new Response(JSON.stringify({ error: "Failed to parse AI response" }), {
            status: 500, headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
          });
        }
      }

      return new Response(JSON.stringify({ reply: aiResponse || "No response generated." }), {
        headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
      });
    } catch (error) {
      console.error("Worker Error:", error.message);
      return new Response(
        JSON.stringify({ error: "Internal Server Error" }),
        { status: 500, headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" } }
      );
    }
  },
};
