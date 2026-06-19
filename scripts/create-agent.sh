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
API_KEY="${API_KEY#"${API_KEY%%[![:space:]]*}"}"
API_KEY="${API_KEY%"${API_KEY##*[![:space:]]}"}"
if [[ "${API_KEY}" == *" "* ]]; then
  echo "API_KEY must be the single encoded value from Kibana (no spaces)."
  exit 1
fi
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
                "observability.get_traces",
                "observability.get_trace_metrics",
                "observability.get_logs",
                "platform.core.execute_esql",
                "platform.core.list_indices",
            ]
        }],
    },
}
json.dump(payload, open(out_path, "w"))
PY

HTTP_CODE="$(curl -s -o /tmp/bhargava-agent-response.json -w '%{http_code}' \
  -X POST "${KIBANA_URL%/}/api/agent_builder/agents" \
  -H "Authorization: ApiKey ${API_KEY}" \
  -H "kbn-xsrf: true" \
  -H "Content-Type: application/json" \
  -d @"${TMP_PAYLOAD}")"

if [ "${HTTP_CODE}" = "409" ]; then
  HTTP_CODE="$(curl -s -o /tmp/bhargava-agent-response.json -w '%{http_code}' \
    -X PUT "${KIBANA_URL%/}/api/agent_builder/agents/bhargava-tutor" \
    -H "Authorization: ApiKey ${API_KEY}" \
    -H "kbn-xsrf: true" \
    -H "Content-Type: application/json" \
    -d @"${TMP_PAYLOAD}")"
fi

if [ "${HTTP_CODE}" -ge 200 ] && [ "${HTTP_CODE}" -lt 300 ]; then
  echo "Agent bhargava-tutor ready (HTTP ${HTTP_CODE}). Open Kibana → Agent Builder."
  exit 0
fi

echo "Agent create failed (HTTP ${HTTP_CODE})."
cat /tmp/bhargava-agent-response.json 2>/dev/null || true
echo ""
if [ "${HTTP_CODE}" = "401" ] || [ "${HTTP_CODE}" = "403" ]; then
  echo "Fix: Kibana → API keys → create key with Agent Builder scope."
  echo "Use the full encoded key (id:secret base64), not a fragment."
fi
exit 1
