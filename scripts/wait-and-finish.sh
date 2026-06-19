#!/usr/bin/env bash
# Open Kibana key pages, wait until .env has valid keys, then finish setup automatically.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"
chmod +x scripts/*.sh 2>/dev/null || true

# shellcheck disable=SC1091
source .env 2>/dev/null || true

echo "==> Bhargava — waiting for valid Elastic Cloud keys in .env"
echo ""
echo "Do ONE of the following:"
echo ""
echo "  A) Auto-create via Elastic Cloud API (Serverless — recommended):"
echo "     EC_API_KEY=<org-owner key from cloud.elastic.co/account/keys> ./scripts/create-elastic-keys.sh"
echo "     then: ./scripts/wait-and-finish.sh --skip-wait"
echo ""
echo "  A2) Hosted cluster only (password login enabled):"
echo "     ELASTIC_USER=you@email.com ELASTIC_PASSWORD=secret ./scripts/create-elastic-keys.sh"
echo ""
echo "  B) Paste keys manually into .env, then this script detects them:"
echo "     API_KEY=<encoded key from Kibana → API keys → Agent Builder>"
echo "     OTEL_EXPORTER_OTLP_HEADERS=\"Authorization=ApiKey <encoded OTLP key>\""
echo "     (OTLP key from Add data → OpenTelemetry → Create API Key)"
echo ""
echo "  C) Agent only (no APM): ./scripts/prepare-kibana-import.sh"
echo ""

if [ "${1:-}" = "--skip-wait" ]; then
  ./scripts/finish-setup.sh
  exit $?
fi

open "${KIBANA_URL}/app/integrations/browse/opentelemetry" 2>/dev/null || true
open "${KIBANA_URL}/app/management/security/api_keys" 2>/dev/null || true

echo "Opened Kibana in browser. Waiting for valid keys in .env (Ctrl+C to cancel)..."
for i in $(seq 1 120); do
  OTLP_OK=0 AGENT_OK=0
  ./scripts/validate-otlp.sh >/dev/null 2>&1 && OTLP_OK=1 || true
  ./scripts/validate-api-key.sh >/dev/null 2>&1 && AGENT_OK=1 || true
  if [ "${OTLP_OK}" = "1" ] && [ "${AGENT_OK}" = "1" ]; then
    echo ""
    echo "✓ Valid keys detected — finishing setup..."
    ./scripts/finish-setup.sh
    exit 0
  fi
  if [ "${AGENT_OK}" = "1" ] && [ "${OTLP_OK}" = "0" ]; then
    echo -n "."
  elif [ "${OTLP_OK}" = "1" ] && [ "${AGENT_OK}" = "0" ]; then
    echo -n ","
  else
    echo -n "."
  fi
  sleep 5
done

echo ""
echo "Timed out after 10 minutes. Paste keys into .env and run: ./scripts/finish-setup.sh"
exit 1
