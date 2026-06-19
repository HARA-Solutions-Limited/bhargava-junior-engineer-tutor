#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEMO_DIR="${ROOT_DIR}/vendor/elastic-opentelemetry-demo"
FIX_FILE="${ROOT_DIR}/config/docker-compose.bhargava-fix.yml"

if [ ! -d "${DEMO_DIR}/.git" ]; then
  echo "Run ./bootstrap.sh first."
  exit 1
fi

chmod +x "${ROOT_DIR}/scripts/sync-elastic-config.sh"
"${ROOT_DIR}/scripts/sync-elastic-config.sh"

cd "${DEMO_DIR}"
echo "==> Starting Astronomy Shop (Elastic fork + Bhargava hack-night config)"
docker compose \
  --env-file .env \
  --env-file .env.override \
  -f docker-compose.yml \
  -f docker-compose.elastic.yml \
  -f "${FIX_FILE}" \
  up --force-recreate --remove-orphans --detach

echo ""
echo "Waiting for shop at http://localhost:8080 ..."
for _ in $(seq 1 60); do
  if curl -sf "http://localhost:8080/" -o /dev/null 2>/dev/null; then
    echo "Shop is up."
    exit 0
  fi
  sleep 2
done

echo "Shop not ready yet — check: docker compose ps"
exit 1
