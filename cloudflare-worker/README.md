# Lycoris IGDB Cloudflare Worker Proxy

This Cloudflare Worker securely proxies queries to IGDB v4 while keeping your Twitch Client ID and Client Secret safe in Cloudflare environment secrets.

It includes **Cloudflare Workers KV server-side edge caching** with a **90-day automatic expiration (TTL)** to keep response times under 15ms while protecting your 1 GB storage limit.

---

## Architecture & Caching Policy

- **Default Proxy Users**: Requests hit the Cloudflare Worker proxy and query the global KV edge cache first. On a cache hit (`X-Lycoris-Cache: HIT`), data is returned in ~10ms. On a cache miss, data is fetched from IGDB, returned immediately to the client, and saved to KV in the background with a 90-day TTL.
- **Custom User Credentials**: If a user enters their own Twitch Client ID & Secret in the Lycoris app settings, requests connect directly to IGDB v4 from their device, completely bypassing the Cloudflare Worker proxy and KV storage.
- **90-Day Auto-Purge**: All KV entries expire automatically after 90 days (`expirationTtl: 7776000`), ensuring the 1 GB storage quota remains safe from long-term bloat.

---

## Deployment Steps

### 1. Install Wrangler CLI & Log In
```bash
npm install -g wrangler
wrangler login
```

### 2. Create the Cloudflare Workers KV Namespace
Create the production KV namespace:
```bash
wrangler kv:namespace create "IGDB_CACHE"
```

The output will display:
```toml
[[kv_namespaces]]
binding = "IGDB_CACHE"
id = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
```

Copy the generated `id` and paste it into `wrangler.toml`:
```toml
[[kv_namespaces]]
binding = "IGDB_CACHE"
id = "your_generated_id_here"
```

*(Optional) Create a preview namespace for local development:*
```bash
wrangler kv:namespace create "IGDB_CACHE" --preview
```

### 3. Set Your Twitch Developer Secrets
```bash
wrangler secret put TWITCH_CLIENT_ID
# Enter your Twitch Client ID

wrangler secret put TWITCH_CLIENT_SECRET
# Enter your Twitch Client Secret
```

### 4. Deploy the Worker
```bash
wrangler deploy
```

### 5. Verify Health & Cache Status
Open your deployed worker URL in your browser:
```bash
https://lycoris-igdb-proxy.<subdomain>.workers.dev/health
```
You should see:
```json
{
  "status": "ok",
  "service": "Lycoris IGDB Cloudflare Proxy",
  "hasCredentials": true,
  "hasKVCache": true,
  "cacheTtl": "90 days"
}
```

Copy your deployed worker URL and paste it into **Lycoris Settings > Cloudflare Worker Proxy URL** (or use the built-in default).
