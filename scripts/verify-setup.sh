#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

pass=0
fail=0

check() {
  local name="$1"
  shift
  if "$@"; then
    echo "  ✓ ${name}"
    pass=$((pass + 1))
  else
    echo "  ✗ ${name}"
    fail=$((fail + 1))
  fi
}

echo "==> Bhargava hackathon gates (see docs/hackathon-sprint-plan.md)"
echo ""

if [ -f .env ]; then
  # shellcheck disable=SC1091
  source .env
fi

check "Shop HTTP 200" curl -sf "${SHOP_URL:-http://localhost:8080}/" -o /dev/null
check "frontend-proxy running" bash -c 'docker ps --format "{{.Names}}" | grep -qx frontend-proxy'
check "otel-collector running" bash -c 'docker ps --format "{{.Names}}" | grep -qx otel-collector'
check "shipping stable (not restarting)" bash -c 'test "$(docker inspect -f "{{.State.Restarting}}" shipping 2>/dev/null)" = "false"'

if [ -n "${OTEL_EXPORTER_OTLP_ENDPOINT:-}" ]; then
  host="${OTEL_EXPORTER_OTLP_ENDPOINT#https://}"
  host="${host%%/*}"
  host="${host%%:*}"
  check "OTLP ingest DNS resolves" bash -c "getent hosts '${host}' >/dev/null 2>&1 || nslookup '${host}' >/dev/null 2>&1"
else
  echo "  ✗ OTLP ingest DNS resolves (.env missing OTEL_EXPORTER_OTLP_ENDPOINT)"
  fail=$((fail + 1))
fi

if [ -n "${API_KEY:-}" ]; then
  code="$(curl -s -o /dev/null -w '%{http_code}' "${KIBANA_URL%/}/api/agent_builder/agents" \
    -H "Authorization: ApiKey ${API_KEY}" -H "kbn-xsrf: true")"
  check "Kibana API key (agent_builder ${code})" test "${code}" = "200" -o "${code}" = "404"
else
  echo "  ✗ Kibana API key set in .env"
  fail=$((fail + 1))
fi

if ./scripts/validate-otlp.sh >/dev/null 2>&1; then
  auth_failures="$(docker logs otel-collector 2>&1 | tail -100 | grep 'Exporting failed' | grep -cE '401|403|Unauthenticated|not authenticated' || true)"
  metric_noise="$(docker logs otel-collector 2>&1 | tail -100 | grep 'Exporting failed' | grep -c 'cumulative histogram' || true)"
  if [ "${auth_failures}" -eq 0 ]; then
    if [ "${metric_noise}" -gt 0 ]; then
      echo "  ✓ Collector exporting to Elastic (ignoring unsupported histogram metrics)"
    else
      echo "  ✓ Collector exporting to Elastic (no recent auth failures)"
    fi
    pass=$((pass + 1))
  else
    echo "  ✗ Collector auth failures in last 100 log lines (${auth_failures})"
    fail=$((fail + 1))
  fi
else
  recent="$(docker logs otel-collector 2>&1 | tail -50 | grep -c 'Exporting failed' || true)"
  if [ "${recent}" -eq 0 ]; then
    echo "  ✓ Collector running (debug-only until valid OTLP key)"
    pass=$((pass + 1))
  else
    echo "  ✗ Collector export failures in last 50 log lines (${recent})"
    fail=$((fail + 1))
  fi
fi

echo ""
echo "Passed: ${pass}  Failed: ${fail}"
if [ "${fail}" -gt 0 ]; then
  echo ""
  echo "Blockers:"
  echo "  • Serverless: EC_API_KEY=<org-owner key> ./scripts/create-elastic-keys.sh"
  echo "  • Or paste full encoded keys into .env (see ./scripts/wait-and-finish.sh)"
  echo "  • Then: ./scripts/sync-elastic-config.sh && ./scripts/finish-setup.sh"
  exit 1
fi

echo ""
echo "Local stack looks good. Run ./scripts/create-agent.sh and validate in Kibana Agent Builder."
