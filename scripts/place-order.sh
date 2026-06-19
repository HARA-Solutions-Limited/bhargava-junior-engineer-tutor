#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [ -f "${ROOT_DIR}/.env" ]; then
  # shellcheck disable=SC1091
  source "${ROOT_DIR}/.env"
fi

SHOP_URL="${SHOP_URL:-http://localhost:8080}"
SESSION_ID="${1:-bhargava-checkout-$(date +%s)}"
CURRENCY="${2:-USD}"

products="$(curl -sf "${SHOP_URL}/api/products?currencyCode=${CURRENCY}")"
product_a="$(printf '%s' "${products}" | python3 -c "import sys,json; print(json.load(sys.stdin)[0]['id'])")"
product_b="$(printf '%s' "${products}" | python3 -c "import sys,json; p=json.load(sys.stdin); print(p[1]['id'] if len(p)>1 else p[0]['id'])")"

echo "==> Placing checkout order (session=${SESSION_ID})"
for pid in "${product_a}" "${product_b}"; do
  curl -sf -X POST "${SHOP_URL}/api/cart?currencyCode=${CURRENCY}" \
    -H "Content-Type: application/json" \
    -d "{\"item\":{\"productId\":\"${pid}\",\"quantity\":1},\"userId\":\"${SESSION_ID}\"}" >/dev/null
  echo "  added ${pid} to cart"
done

order="$(curl -sf -X POST "${SHOP_URL}/api/checkout?currencyCode=${CURRENCY}" \
  -H "Content-Type: application/json" \
  -d "{
    \"userId\": \"${SESSION_ID}\",
    \"userCurrency\": \"${CURRENCY}\",
    \"email\": \"someone@example.com\",
    \"address\": {
      \"streetAddress\": \"1600 Amphitheatre Parkway\",
      \"state\": \"CA\",
      \"country\": \"United States\",
      \"city\": \"Mountain View\",
      \"zipCode\": \"94043\"
    },
    \"creditCard\": {
      \"creditCardNumber\": \"4432-8015-6152-0454\",
      \"creditCardCvv\": 672,
      \"creditCardExpirationYear\": 2030,
      \"creditCardExpirationMonth\": 1
    }
  }")"

order_id="$(printf '%s' "${order}" | python3 -c "import sys,json; print(json.load(sys.stdin).get('orderId',''))" 2>/dev/null || true)"
if [ -z "${order_id}" ]; then
  echo "Checkout failed. Response: ${order}"
  exit 1
fi

echo "Order placed: ${order_id}"
echo "Wait ~60s, then check Kibana APM for checkout traces."
