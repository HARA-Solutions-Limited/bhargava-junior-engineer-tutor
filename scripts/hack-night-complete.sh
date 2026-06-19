#!/usr/bin/env bash
# Run the full Bhargava + DevOps Society hack night flow (Docker path).
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

echo "==> Step 1/6: Bootstrap (clone demo if needed)"
./bootstrap.sh

echo ""
echo "==> Step 2/6: Start Astronomy Shop → Elastic Cloud"
./scripts/start-demo.sh

echo ""
echo "==> Step 3/6: Verify local gates"
if ! ./scripts/verify-setup.sh; then
  echo ""
  echo "Fix Elastic Cloud credentials in .env (see docs/hack-night-alignment.md), then re-run."
  exit 1
fi

echo ""
echo "==> Step 4/6: Deploy Bhargava agent"
./scripts/create-agent.sh

echo ""
echo "==> Step 5/6: Generate traffic + checkout traces"
./scripts/generate-traffic.sh 10
./scripts/place-order.sh

echo ""
echo "==> Step 6/6: Open Kibana + shop for demo"
if [ -f .env ]; then
  # shellcheck disable=SC1091
  source .env
fi
open "${KIBANA_URL}/app/apm/services" 2>/dev/null || true
open "${KIBANA_URL}/app/agent_builder" 2>/dev/null || true
open "http://localhost:8080" 2>/dev/null || true

echo ""
echo "Hack night + Bhargava ready. Ask Bhargava the core demo question:"
echo '  "I just clicked Place Order. Walk me through what happened using a real checkout trace from the last 30 minutes. Include Kibana links."'
echo ""
echo "Full checklist: docs/hack-night-alignment.md"
