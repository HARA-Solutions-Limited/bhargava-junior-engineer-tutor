#!/usr/bin/env bash
# Create OTLP + Agent Builder API keys and update .env automatically.
#
# Serverless (Elastic Cloud Observability) — recommended:
#   EC_API_KEY=<org owner key from cloud.elastic.co/account/keys> ./scripts/create-elastic-keys.sh
#
# Hosted / ECE (basic auth still enabled):
#   ELASTIC_USER=you@email.com ELASTIC_PASSWORD=secret ./scripts/create-elastic-keys.sh
#
# Manual fallback: paste encoded keys into .env, then ./scripts/sync-elastic-config.sh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ROOT_DIR}/.env"
COOKIE_JAR="$(mktemp)"
trap 'rm -f "${COOKIE_JAR}"' EXIT

# shellcheck disable=SC1091
source "${ENV_FILE}"

: "${KIBANA_URL:?Set KIBANA_URL in .env}"
: "${ELASTICSEARCH_URL:?Set ELASTICSEARCH_URL in .env}"

EC_API_KEY="${EC_API_KEY:-${ELASTIC_CLOUD_API_KEY:-}}"

serverless_project() {
  curl -s -o /dev/null -w '%{http_code}' \
    -X POST "${KIBANA_URL%/}/internal/security/login" \
    -H "kbn-xsrf: true" -H "Content-Type: application/json" \
    -d '{"providerType":"basic","providerName":"basic","currentURL":"'"${KIBANA_URL}"'/login","params":{"username":"x","password":"x"}}'
}

update_env() {
  local otlp_key="$1"
  local agent_key="$2"
  local endpoint="$3"
  python3 - "${ENV_FILE}" "${otlp_key}" "${agent_key}" "${endpoint}" <<'PY'
import re, sys
path, otlp_key, agent_key, es_url = sys.argv[1:5]
text = open(path).read()
text = re.sub(r'^API_KEY=.*$', f'API_KEY={agent_key}', text, flags=re.M)
text = re.sub(r'^OTEL_EXPORTER_OTLP_ENDPOINT=.*$', f'OTEL_EXPORTER_OTLP_ENDPOINT={es_url}', text, flags=re.M)
text = re.sub(
    r'^OTEL_EXPORTER_OTLP_HEADERS=.*$',
    f'OTEL_EXPORTER_OTLP_HEADERS="Authorization=ApiKey {otlp_key}"',
    text, flags=re.M,
)
open(path, "w").write(text)
print(f"Updated {path}")
PY
}

create_keys_via_cloud_api() {
  local cloud_key="$1"
  local cloud_base="${EC_BASE_URL:-https://api.elastic-cloud.com}/api/v1"

  echo "==> Discovering organization and project via Elastic Cloud API..."
  ORG_JSON="$(curl -sf "${cloud_base}/organizations" -H "Authorization: ApiKey ${cloud_key}")"
  ORG_ID="$(printf '%s' "${ORG_JSON}" | python3 -c "
import sys, json
orgs = json.load(sys.stdin).get('organizations') or []
if not orgs:
    raise SystemExit('No organizations found for this Cloud API key')
print(orgs[0]['id'])
")"

  PROJECTS_JSON="$(curl -sf "${cloud_base}/organizations/${ORG_ID}/projects" -H "Authorization: ApiKey ${cloud_key}")"
  PROJECT_ID="$(printf '%s' "${PROJECTS_JSON}" "${KIBANA_URL}" "${ELASTICSEARCH_URL}" <<'PY'
import json, sys, urllib.parse
projects_json, kibana_url, es_url = sys.argv[1:4]
projects = json.loads(projects_json).get('projects') or []
hosts = {
    urllib.parse.urlparse(kibana_url).hostname or "",
    urllib.parse.urlparse(es_url).hostname or "",
}
for p in projects:
    for endpoint in (p.get('endpoints') or {}).values():
        if isinstance(endpoint, str) and any(h and h in endpoint for h in hosts if h):
            print(p['id'])
            raise SystemExit(0)
    name = (p.get('name') or "").lower()
    alias = (p.get('alias') or "").lower()
    for h in hosts:
        if h and (name in h or alias in h or h.split(".")[0].endswith(name.replace(" ", "-"))):
            print(p['id'])
            raise SystemExit(0)
if projects:
    print(projects[0]['id'])
else:
    raise SystemExit('No Serverless projects found')
PY
)"

  echo "    org=${ORG_ID} project=${PROJECT_ID}"

  echo "==> Creating unified Cloud API key (ES + Kibana stack access)..."
  KEY_JSON="$(curl -sf -X POST "${cloud_base}/users/auth/keys" \
    -H "Authorization: ApiKey ${cloud_key}" \
    -H "Content-Type: application/json" \
    -d "$(python3 - <<PY
import json
print(json.dumps({
  "description": "bhargava-hack-night",
  "expiration": "30d",
  "role_assignments": {
    "project": {
      "observability": [{
        "role_id": "admin",
        "organization_id": "${ORG_ID}",
        "all": False,
        "project_ids": ["${PROJECT_ID}"],
        "application_roles": ["admin"],
      }]
    }
  },
}))
PY
)")"

  STACK_KEY="$(printf '%s' "${KEY_JSON}" | python3 -c "import sys,json; print(json.load(sys.stdin).get('key',''))")"
  if [ -z "${STACK_KEY}" ]; then
    echo "Failed to create Cloud API key with stack access:"
    echo "${KEY_JSON}"
    exit 1
  fi

  echo "==> Validating stack key against Kibana and OTLP..."
  AGENT_CODE="$(curl -s -o /dev/null -w '%{http_code}' "${KIBANA_URL%/}/api/agent_builder/agents" \
    -H "Authorization: ApiKey ${STACK_KEY}" -H "kbn-xsrf: true")"
  OTLP_CODE="$(curl -s -o /dev/null -w '%{http_code}' -X POST "${ELASTICSEARCH_URL%/}/v1/traces" \
    -H "Authorization: ApiKey ${STACK_KEY}" \
    -H "Content-Type: application/x-protobuf" \
    --data-binary @/dev/null)"

  if [ "${AGENT_CODE}" != "200" ] && [ "${AGENT_CODE}" != "404" ]; then
    echo "Stack key rejected by Agent Builder (HTTP ${AGENT_CODE})."
    echo "Create keys manually in Kibana → API keys and Add data → OpenTelemetry."
    exit 1
  fi
  if [ "${OTLP_CODE}" != "200" ] && [ "${OTLP_CODE}" != "202" ] && [ "${OTLP_CODE}" != "204" ]; then
    echo "Stack key rejected by OTLP endpoint (HTTP ${OTLP_CODE})."
    echo "Create a dedicated OTLP key: Kibana → Add data → OpenTelemetry → Create API Key"
    exit 1
  fi

  update_env "${STACK_KEY}" "${STACK_KEY}" "${ELASTICSEARCH_URL}"
  echo "✓ Cloud API key works for Agent Builder and OTLP export"
}

create_keys_via_kibana_login() {
  ELASTIC_USER="${ELASTIC_USER:-${KIBANA_USER:-}}"
  ELASTIC_PASSWORD="${ELASTIC_PASSWORD:-${KIBANA_PASSWORD:-}}"

  if [ -z "${ELASTIC_USER}" ]; then
    read -r -p "Elastic Cloud email: " ELASTIC_USER
  fi
  if [ -z "${ELASTIC_PASSWORD}" ]; then
    read -r -s -p "Elastic Cloud password: " ELASTIC_PASSWORD
    echo ""
  fi

  export ELASTIC_USER ELASTIC_PASSWORD KIBANA_URL ELASTICSEARCH_URL

  echo "==> Logging into Kibana..."
  LOGIN_CODE="$(curl -s -c "${COOKIE_JAR}" -b "${COOKIE_JAR}" -o /tmp/kibana-login.json -w '%{http_code}' \
    -X POST "${KIBANA_URL%/}/internal/security/login" \
    -H "kbn-xsrf: true" \
    -H "Content-Type: application/json" \
    -d "$(python3 - <<'PY'
import json, os
print(json.dumps({
  "providerType": "basic",
  "providerName": "basic",
  "currentURL": os.environ["KIBANA_URL"] + "/login",
  "params": {"username": os.environ["ELASTIC_USER"], "password": os.environ["ELASTIC_PASSWORD"]},
}))
PY
)")"

  if [ "${LOGIN_CODE}" != "200" ] && [ "${LOGIN_CODE}" != "204" ]; then
    echo "Login failed (HTTP ${LOGIN_CODE})."
    cat /tmp/kibana-login.json 2>/dev/null || true
    exit 1
  fi
  echo "✓ Logged in"

  echo "==> Creating OTLP writer API key..."
  OTLP_JSON="$(curl -s -c "${COOKIE_JAR}" -b "${COOKIE_JAR}" \
    -X POST "${ELASTICSEARCH_URL}/_security/api_key" \
    -H "kbn-xsrf: true" \
    -H "Content-Type: application/json" \
    -d '{
      "name": "bhargava-otlp-writer",
      "role_descriptors": {
        "otlp_writer": {
          "applications": [{
            "application": "apm",
            "resources": ["*"],
            "privileges": ["event:write"]
          }]
        }
      }
    }')"

  OTLP_ENCODED="$(printf '%s' "${OTLP_JSON}" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('encoded',''))")"
  if [ -z "${OTLP_ENCODED}" ]; then
    echo "Failed to create OTLP key:"
    echo "${OTLP_JSON}"
    exit 1
  fi
  echo "✓ OTLP key created"

  echo "==> Creating Agent Builder API key..."
  AGENT_JSON="$(curl -s -c "${COOKIE_JAR}" -b "${COOKIE_JAR}" \
    -X POST "${KIBANA_URL%/}/internal/security/api_key" \
    -H "kbn-xsrf: true" \
    -H "Content-Type: application/json" \
    -d '{
      "name": "bhargava-agent-builder",
      "metadata": {},
      "kibana_role_descriptors": {
        "agent_builder": {
          "applications": [{
            "application": "kibana-.kibana",
            "resources": ["*"],
            "privileges": ["all"]
          }]
        }
      }
    }' 2>/dev/null || echo '{}')"

  AGENT_ENCODED="$(printf '%s' "${AGENT_JSON}" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print(d.get('encoded') or d.get('api_key', {}).get('encoded', ''))
" 2>/dev/null || true)"

  if [ -z "${AGENT_ENCODED}" ]; then
    AGENT_JSON="$(curl -s -c "${COOKIE_JAR}" -b "${COOKIE_JAR}" \
      -X POST "${ELASTICSEARCH_URL}/_security/api_key" \
      -H "kbn-xsrf: true" \
      -H "Content-Type: application/json" \
      -d '{"name":"bhargava-agent-builder","role_descriptors":{"admin":{"cluster":["all"],"index":[{"names":["*"],"privileges":["read","view_index_metadata"]}]}}}')"
    AGENT_ENCODED="$(printf '%s' "${AGENT_JSON}" | python3 -c "import sys,json; print(json.load(sys.stdin).get('encoded',''))")"
  fi

  if [ -z "${AGENT_ENCODED}" ]; then
    echo "Failed to create Agent Builder key. Create manually in Kibana → API keys."
    echo "${AGENT_JSON}"
    exit 1
  fi
  echo "✓ Agent Builder key created"

  update_env "${OTLP_ENCODED}" "${AGENT_ENCODED}" "${ELASTICSEARCH_URL}"
}

print_serverless_manual_steps() {
  echo ""
  echo "Elastic Cloud Serverless does not support password login to Kibana APIs."
  echo ""
  echo "Option A — auto-create (fastest, needs org-owner Cloud API key):"
  echo "  1. Create key at https://cloud.elastic.co/account/keys (Organization owner)"
  echo "  2. Run: EC_API_KEY=<that-key> ./scripts/create-elastic-keys.sh"
  echo ""
  echo "Option B — paste project keys manually into .env:"
  echo "  • OTLP:  ${KIBANA_URL}/app/integrations/browse/opentelemetry"
  echo "           → Managed OTLP Endpoint → Create API Key → copy full **encoded** value"
  echo "  • Agent: ${KIBANA_URL}/app/management/security/api_keys"
  echo "           → Create API key → enable Agent Builder → copy full **encoded** value"
  echo ""
  echo "Then: ./scripts/sync-elastic-config.sh && ./scripts/finish-setup.sh"
  echo ""
  echo "Your current keys look like UI fragments (contain '-'), not valid base64 encoded keys."
}

LOGIN_PROBE="$(serverless_project)"
if [ -n "${EC_API_KEY}" ]; then
  create_keys_via_cloud_api "${EC_API_KEY}"
elif [ "${LOGIN_PROBE}" = "400" ]; then
  if [ -n "${ELASTIC_USER:-${KIBANA_USER:-}}" ] && [ -n "${ELASTIC_PASSWORD:-${KIBANA_PASSWORD:-}}" ]; then
    echo "Serverless project detected — password login is disabled; use EC_API_KEY instead."
  fi
  print_serverless_manual_steps
  exit 1
else
  create_keys_via_kibana_login
fi

echo ""
echo "Done. Run: ./scripts/sync-elastic-config.sh && ./scripts/finish-setup.sh"
