#!/usr/bin/env bash
# Sync root .env → vendor demo (.env.override) + collector config (Elastic or debug-local).
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEMO_DIR="${ROOT_DIR}/vendor/elastic-opentelemetry-demo"
OVERRIDE="${DEMO_DIR}/.env.override"
COLLECTOR_ELASTIC="${ROOT_DIR}/config/otelcol-elastic-hacknight.yaml"
COLLECTOR_DEBUG="${ROOT_DIR}/config/otelcol-debug-local.yaml"
COLLECTOR_DST="${DEMO_DIR}/src/otel-collector/otelcol-elastic-hacknight.yaml"
COLLECTOR_DEBUG_DST="${DEMO_DIR}/src/otel-collector/otelcol-debug-local.yaml"

if [ ! -f "${ROOT_DIR}/.env" ]; then
  echo "Missing .env — run ./bootstrap.sh and edit credentials (docs/hack-night-alignment.md)."
  exit 1
fi

# shellcheck disable=SC1091
source "${ROOT_DIR}/.env"

mkdir -p "$(dirname "${COLLECTOR_DST}")"
cp "${COLLECTOR_ELASTIC}" "${COLLECTOR_DST}"
cp "${COLLECTOR_DEBUG}" "${COLLECTOR_DEBUG_DST}"

USE_ELASTIC=0
if "${ROOT_DIR}/scripts/validate-otlp.sh" >/dev/null 2>&1; then
  USE_ELASTIC=1
fi

COLLECTOR_CONFIG="./src/otel-collector/otelcol-elastic-hacknight.yaml"
if [ "${USE_ELASTIC}" = "0" ]; then
  COLLECTOR_CONFIG="./src/otel-collector/otelcol-debug-local.yaml"
  echo "Note: OTLP credentials invalid or missing — collector will export to debug only (no Elastic Cloud APM yet)."
fi

python3 - "${OVERRIDE}" "${OTEL_EXPORTER_OTLP_ENDPOINT:-}" "${OTEL_EXPORTER_OTLP_HEADERS:-}" "${COLLECTOR_CONFIG}" <<'PY'
import re, sys
from pathlib import Path

override_path, endpoint, headers, collector_config = sys.argv[1:5]
text = Path(override_path).read_text() if Path(override_path).exists() else ""

otlp_key = ""
if headers:
    m = re.search(r"ApiKey\s+([^\"]+)", headers)
    if m:
        otlp_key = m.group(1).strip()

def upsert(key, value):
    global text
    line = f'{key}="{value}"'
    if re.search(rf"^{re.escape(key)}=", text, flags=re.M):
        text = re.sub(rf"^{re.escape(key)}=.*$", line, text, flags=re.M)
    else:
        text = text.rstrip() + "\n" + line + "\n"

upsert("OTEL_COLLECTOR_CONFIG", collector_config)
if endpoint and otlp_key:
    upsert("ELASTIC_OTLP_ENDPOINT", endpoint)
    upsert("ELASTIC_OTLP_API_KEY", otlp_key)
elif endpoint:
    upsert("ELASTIC_OTLP_ENDPOINT", endpoint)

Path(override_path).write_text(text)
print(f"Collector config: {collector_config}")
print(f"Updated {override_path}")
PY

if [ "${USE_ELASTIC}" = "1" ]; then
  echo "Synced Elastic collector → ${COLLECTOR_DST}"
else
  echo "Synced debug-local collector → ${COLLECTOR_DEBUG_DST}"
fi
