#!/usr/bin/env bash
# Finish hack-night setup: keys → sync → demo → agent → checkout → verify
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"
chmod +x scripts/*.sh 2>/dev/null || true

echo "==> Step 1: Check credentials"
OTLP_OK=0
AGENT_OK=0
./scripts/validate-otlp.sh >/dev/null 2>&1 && OTLP_OK=1 || true
./scripts/validate-api-key.sh >/dev/null 2>&1 && AGENT_OK=1 || true

if [ "${OTLP_OK}" = "0" ] || [ "${AGENT_OK}" = "0" ]; then
  if [ -n "${ELASTIC_PASSWORD:-}" ] || [ -n "${KIBANA_PASSWORD:-}" ]; then
    echo "    Creating API keys via Kibana login..."
    ./scripts/create-elastic-keys.sh
  else
    echo ""
    echo "Credentials in .env are invalid or incomplete."
    echo ""
    echo "Option A — auto-create keys via Elastic Cloud API (Serverless):"
    echo "  EC_API_KEY=<org-owner key from cloud.elastic.co/account/keys> ./scripts/create-elastic-keys.sh"
    echo ""
    echo "Option A2 — hosted cluster (password login):"
    echo "  ELASTIC_USER=your@email.com ELASTIC_PASSWORD=yourpassword ./scripts/create-elastic-keys.sh"
    echo ""
    echo "Option B — paste keys manually into .env, then re-run:"
    echo "  API_KEY=<full encoded key from Kibana → API keys → Agent Builder>"
    echo "  OTEL_EXPORTER_OTLP_HEADERS=\"Authorization=ApiKey <full encoded OTLP key>\""
    echo "  Get OTLP key: Kibana → Add data → OpenTelemetry → Create API Key"
    echo ""
    echo "Option C — create Bhargava manually in Kibana UI:"
    echo "  ./scripts/prepare-kibana-import.sh"
    echo "  Open Agent Builder → Create agent → paste from agent/bhargava-ui-import.txt"
    echo ""
    if [ "${OTLP_OK}" = "0" ] && [ "${AGENT_OK}" = "0" ]; then
      echo "Continuing with local stack only (APM + agent need valid keys)..."
      echo ""
    fi
  fi
fi

echo "==> Step 2: Sync Elastic config"
./scripts/sync-elastic-config.sh

echo "==> Step 3: Start / refresh demo stack"
./scripts/start-demo.sh

echo "==> Step 4: Verify local gates"
./scripts/verify-setup.sh || true

echo "==> Step 5: Deploy Bhargava agent (API)"
if ./scripts/validate-api-key.sh >/dev/null 2>&1; then
  ./scripts/create-agent.sh
else
  echo "    Skipping API agent create — use ./scripts/prepare-kibana-import.sh for Kibana UI"
fi

echo "==> Step 6: Traffic + checkout traces"
./scripts/generate-traffic.sh 5
./scripts/place-order.sh

echo ""
echo "==> Done. Open:"
# shellcheck disable=SC1091
source .env 2>/dev/null || true
echo "  Shop:    http://localhost:8080"
echo "  Kibana:  ${KIBANA_URL}/app/apm/services"
echo "  Agent:   ${KIBANA_URL}/app/agent_builder"
echo ""
echo "Core demo question:"
echo '  "I just clicked Place Order. Walk me through what happened using a real checkout trace from the last 30 minutes. Include Kibana links."'
