# Lycoris IGDB Cloudflare Worker Proxy

This Cloudflare Worker securely proxies queries to IGDB v4 while keeping your Twitch Client ID and Client Secret safe in Cloudflare environment secrets.

## Deployment Steps

1. Install Wrangler (Cloudflare CLI) if not already installed:
   ```bash
   npm install -g wrangler
   ```

2. Log into Cloudflare:
   ```bash
   wrangler login
   ```

3. Set your Twitch Developer secrets:
   ```bash
   wrangler secret put TWITCH_CLIENT_ID
   # Enter your Twitch Client ID

   wrangler secret put TWITCH_CLIENT_SECRET
   # Enter your Twitch Client Secret
   ```

4. Deploy the worker:
   ```bash
   wrangler deploy
   ```

5. Copy your deployed worker URL (e.g., `https://lycoris-igdb-proxy.<subdomain>.workers.dev`) and paste it into **Lycoris Settings > Cloudflare Worker Proxy URL**.
