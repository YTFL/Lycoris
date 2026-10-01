/**
 * Lycoris — IGDB v4 Cloudflare Worker Proxy
 *
 * Securely proxies APICalypse queries to the IGDB v4 API while keeping
 * your Twitch Client-ID and Client-Secret safe on the server side.
 *
 * Environment Secrets required in Cloudflare Worker:
 * - TWITCH_CLIENT_ID: Your Twitch Application Client ID
 * - TWITCH_CLIENT_SECRET: Your Twitch Application Client Secret
 */

// In-memory token cache for worker isolates
let cachedToken = null;
let tokenExpiresAt = 0;

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization, Client-ID',
  'Access-Control-Max-Age': '86400',
};

async function getTwitchAppToken(clientId, clientSecret) {
  const now = Date.now();
  // Return cached token if valid with 5-minute safety buffer
  if (cachedToken && tokenExpiresAt > now + 300000) {
    return cachedToken;
  }

  const tokenUrl = `https://id.twitch.tv/oauth2/token?client_id=${clientId}&client_secret=${clientSecret}&grant_type=client_credentials`;
  const response = await fetch(tokenUrl, { method: 'POST' });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`Failed to obtain Twitch OAuth token: ${response.status} ${errorText}`);
  }

  const data = await response.json();
  cachedToken = data.access_token;
  tokenExpiresAt = now + (data.expires_in * 1000);
  return cachedToken;
}

export default {
  async fetch(request, env) {
    // Handle CORS preflight
    if (request.method === 'OPTIONS') {
      return new Response(null, {
        status: 204,
        headers: CORS_HEADERS,
      });
    }

    const url = new URL(request.url);

    // Health check endpoint
    if (url.pathname === '/' || url.pathname === '/health') {
      return new Response(
        JSON.stringify({
          status: 'ok',
          service: 'Lycoris IGDB Cloudflare Proxy',
          timestamp: new Date().toISOString(),
          hasCredentials: Boolean(env.TWITCH_CLIENT_ID && env.TWITCH_CLIENT_SECRET),
        }),
        {
          status: 200,
          headers: {
            'Content-Type': 'application/json',
            ...CORS_HEADERS,
          },
        }
      );
    }

    // Check secrets
    const clientId = env.TWITCH_CLIENT_ID;
    const clientSecret = env.TWITCH_CLIENT_SECRET;

    if (!clientId || !clientSecret) {
      return new Response(
        JSON.stringify({
          error: 'Missing TWITCH_CLIENT_ID or TWITCH_CLIENT_SECRET in Worker environment variables.',
        }),
        {
          status: 500,
          headers: { 'Content-Type': 'application/json', ...CORS_HEADERS },
        }
      );
    }

    // Determine target IGDB endpoint (defaults to /v4/games if root or /games)
    let igdbEndpoint = url.pathname;
    if (igdbEndpoint === '/games') {
      igdbEndpoint = '/v4/games';
    } else if (!igdbEndpoint.startsWith('/v4/')) {
      igdbEndpoint = `/v4${igdbEndpoint}`;
    }

    const targetUrl = `https://api.igdb.com${igdbEndpoint}`;

    try {
      const accessToken = await getTwitchAppToken(clientId, clientSecret);
      const apicalypseQuery = request.method === 'POST' ? await request.text() : '';

      const igdbResponse = await fetch(targetUrl, {
        method: request.method,
        headers: {
          'Client-ID': clientId,
          'Authorization': `Bearer ${accessToken}`,
          'Content-Type': 'text/plain',
        },
        body: request.method === 'POST' ? apicalypseQuery : undefined,
      });

      const responseBody = await igdbResponse.text();

      return new Response(responseBody, {
        status: igdbResponse.status,
        headers: {
          'Content-Type': 'application/json',
          ...CORS_HEADERS,
        },
      });
    } catch (err) {
      return new Response(
        JSON.stringify({
          error: err.message || 'Internal proxy error',
        }),
        {
          status: 502,
          headers: { 'Content-Type': 'application/json', ...CORS_HEADERS },
        }
      );
    }
  },
};
