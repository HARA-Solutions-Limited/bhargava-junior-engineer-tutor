#!/usr/bin/env bash
# Blocker 2 helper — validate API_KEY format before create-agent.sh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "${ROOT_DIR}/.env"

: "${KIBANA_URL:?Set KIBANA_URL in .env}"
: "${API_KEY:?Set API_KEY in .env}"

KEY="${API_KEY#"${API_KEY%%[![:space:]]*}"}"
KEY="${KEY%"${KEY##*[![:space:]]}"}"

echo "==> Blocker 2: validate Kibana API key"
echo ""

# Elastic encoded keys are base64(id:secret) — standard base64, not URL-safe (no '-' mid-string from wrong field)
if [[ "${KEY}" != essu_* ]] && [[ "${KEY}" == *"-"* ]] && [[ "${KEY}" != *"="* ]]; then
  echo "✗ Key looks like a fragment (contains '-' but is not valid base64)."
  echo "  In Kibana → API keys → Create, copy the **encoded** value shown once at creation."
  echo "  It is longer and usually ends with '=' — format: base64 of id:secret"
  echo ""
  echo "  Open: ${KIBANA_URL}/app/management/security/api_keys"
  exit 1
fi

code="$(curl -s -o /tmp/bhargava-key-test.json -w '%{http_code}' \
  "${KIBANA_URL%/}/api/agent_builder/agents" \
  -H "Authorization: ApiKey ${KEY}" \
  -H "kbn-xsrf: true")"

if [ "${code}" = "200" ] || [ "${code}" = "404" ]; then
  echo "✓ API key accepted (HTTP ${code}). Run: ./scripts/create-agent.sh"
  exit 0
fi

echo "✗ API key rejected (HTTP ${code})"
cat /tmp/bhargava-key-test.json 2>/dev/null || true
echo ""
echo "Fix: ${KIBANA_URL}/app/management/security/api_keys"
echo "  → Create API key → enable Agent Builder → copy **encoded** key to .env API_KEY="
exit 1
