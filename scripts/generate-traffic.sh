#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [ -f "${ROOT_DIR}/.env" ]; then
  # shellcheck disable=SC1091
  source "${ROOT_DIR}/.env"
fi

SHOP_URL="${SHOP_URL:-http://localhost:8080}"
ROUNDS="${1:-5}"

echo "==> Generating Astronomy Shop traffic (${ROUNDS} rounds) at ${SHOP_URL}"

for i in $(seq 1 "${ROUNDS}"); do
  curl -sf "${SHOP_URL}/" -o /dev/null && echo "  round ${i}: homepage ok" || echo "  round ${i}: homepage failed"
  curl -sf "${SHOP_URL}/api/products" -o /dev/null 2>/dev/null || true
  sleep 1
done

echo "Done. Place an order manually in the browser for checkout traces."
