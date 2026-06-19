#!/usr/bin/env bash
# Blocker 1 helper — validate OTLP endpoint + key
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "${ROOT_DIR}/.env"

: "${OTEL_EXPORTER_OTLP_ENDPOINT:?Set OTEL_EXPORTER_OTLP_ENDPOINT in .env}"
: "${OTEL_EXPORTER_OTLP_HEADERS:?Set OTEL_EXPORTER_OTLP_HEADERS in .env}"

OTLP_KEY="$(printf '%s' "${OTEL_EXPORTER_OTLP_HEADERS}" | sed -n 's/.*ApiKey[[:space:]]*\([^"[:space:]]*\).*/\1/p')"
ENDPOINT="${OTEL_EXPORTER_OTLP_ENDPOINT%/}"

echo "==> Blocker 1: validate OTLP endpoint"
echo "Endpoint: ${ENDPOINT}"
echo ""

host="${ENDPOINT#https://}"; host="${host%%/*}"; host="${host%%:*}"
if getent hosts "${host}" >/dev/null 2>&1 || nslookup "${host}" >/dev/null 2>&1; then
  echo "✓ DNS resolves for ${host}"
else
  echo "✗ DNS failed for ${host}"
  echo "  Copy Managed OTLP URL from Elastic Cloud → Add data → OpenTelemetry"
  exit 1
fi

if [[ "${OTLP_KEY}" != essu_* ]] && [[ "${OTLP_KEY}" == *"-"* ]] && [[ "${OTLP_KEY}" != *"="* ]]; then
  echo "✗ OTLP API key looks like a fragment (not valid base64)."
  echo "  In Add data → OpenTelemetry → Create API Key, copy the full encoded value."
  exit 1
fi

code="$(curl -s -o /tmp/otlp-test.txt -w '%{http_code}' -X POST "${ENDPOINT}/v1/traces" \
  -H "Authorization: ApiKey ${OTLP_KEY}" \
  -H "Content-Type: application/x-protobuf" \
  --data-binary @/dev/null 2>/dev/null || echo 000)"

case "${code}" in
  200|202|204)
    echo "✓ OTLP endpoint accepts data (HTTP ${code})"
    exit 0
    ;;
  401|403)
    echo "✗ OTLP endpoint reachable but key rejected (HTTP ${code})"
    head -c 200 /tmp/otlp-test.txt 2>/dev/null; echo
    echo "  Create OTLP API key: Elastic Cloud → Add data → OpenTelemetry → Managed OTLP Endpoint"
    exit 1
    ;;
  404)
    echo "✗ OTLP path not found (HTTP 404) — endpoint URL may be wrong for this project"
    cat /tmp/otlp-test.txt 2>/dev/null
    echo "  Re-copy the exact Managed OTLP endpoint from Elastic Cloud console."
    exit 1
    ;;
  *)
    echo "? Unexpected HTTP ${code}"
    cat /tmp/otlp-test.txt 2>/dev/null
    exit 1
    ;;
esac
