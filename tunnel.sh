#!/bin/bash
# Run your Laravel app through a public tunnel so the Flutter app on your phone can reach it.
# Usage: ./tunnel.sh [port]
# Default port: 80 (XAMPP Apache). Use 8080 if your server runs there.

PORT="${1:-80}"
# Path your Laravel app is served at (no leading slash). Adjust if your site is at a different path.
PUBLIC_PATH="giftfr/core/public"

echo "Starting tunnel to localhost:$PORT ..."
echo ""

if command -v ngrok &>/dev/null; then
  echo "Using ngrok. When it starts, copy the HTTPS URL and add /$PUBLIC_PATH"
  echo "Example: https://abc123.ngrok-free.app/$PUBLIC_PATH"
  echo ""
  ngrok http "$PORT"
elif command -v npx &>/dev/null; then
  echo "Using localtunnel. Copy the URL shown below and add /$PUBLIC_PATH"
  echo "Example: https://your-subdomain.loca.lt/$PUBLIC_PATH"
  echo ""
  npx -y localtunnel --port "$PORT"
else
  echo "Install either:"
  echo "  - ngrok: https://ngrok.com/download"
  echo "  - Node.js (for npx localtunnel): https://nodejs.org"
  exit 1
fi
