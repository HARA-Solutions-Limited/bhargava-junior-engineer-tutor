#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if [ -f .env ]; then
  # shellcheck disable=SC1091
  source .env
fi

: "${KIBANA_URL:?Set KIBANA_URL in .env}"
: "${API_KEY:?Set API_KEY in .env}"
KIBANA_BASE_URL="${KIBANA_BASE_URL:-${KIBANA_URL}}"

INSTRUCTIONS_FILE="${ROOT_DIR}/agent/instructions.txt"
TMP_PAYLOAD="$(mktemp)"
trap 'rm -f "${TMP_PAYLOAD}"' EXIT

python3 - "${INSTRUCTIONS_FILE}" "${KIBANA_BASE_URL}" "${TMP_PAYLOAD}" <<'PY'
import json, sys
instructions_path, kibana_url, out_path = sys.argv[1:4]
instructions = open(instructions_path).read().replace("YOUR_KIBANA_URL", kibana_url.rstrip("/"))
payload = {
    "id": "bhargava-tutor",
    "name": "Bhargava — Junior Engineer Tutor",
    "description": "Named after Lord Parasurama (Bhargava). Onboards new engineers to the Astronomy Shop using live APM traces and Kibana links.",
    "labels": ["hack-night", "onboarding", "opentelemetry", "bhargava"],
    "avatar_color": "#FF9933",
    "avatar_symbol": "Bh",
    "configuration": {
        "instructions": instructions,
        "tools": [{
            "tool_ids": [
                "observability.get_services",
                "observability.get_service_topology",
                "observability.get_downstream_dependencies",
                "observability.get_traces",
                "observability.get_trace_metrics",
                "observability.search_logs",
                "observability.get_correlated_logs",
                "platform.core.execute_esql",
                "platform.core.list_indices",
            ]
        }],
    },
}
json.dump(payload, open(out_path, "w"))
PY

curl -sf -X POST "${KIBANA_URL%/}/api/agent_builder/agents" \
  -H "Authorization: ApiKey ${API_KEY}" \
  -H "kbn-xsrf: true" \
  -H "Content-Type: application/json" \
  -d @"${TMP_PAYLOAD}"

echo ""
echo "Agent bhargava-tutor created (or updated — check Kibana on conflict)."
