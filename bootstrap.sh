#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

OTEL_DEMO_REPO="${OTEL_DEMO_REPO:-https://github.com/elastic/opentelemetry-demo.git}"
OTEL_DEMO_DIR="${ROOT_DIR}/vendor/elastic-opentelemetry-demo"

echo "==> Bhargava Junior Engineer Tutor — bootstrap"

if [ ! -f ".env" ]; then
  echo "==> Creating .env from .env.example"
  cp .env.example .env
  echo "    Edit .env with your Elastic Cloud Kibana URL, API key, and OTLP endpoint."
fi

if [ ! -d "${OTEL_DEMO_DIR}/.git" ]; then
  echo "==> Cloning Elastic OpenTelemetry demo"
  mkdir -p vendor
  git clone --depth 1 "${OTEL_DEMO_REPO}" "${OTEL_DEMO_DIR}"
else
  echo "==> OpenTelemetry demo already cloned at vendor/elastic-opentelemetry-demo"
fi

echo ""
echo "Bootstrap complete."
echo ""
echo "Next steps:"
echo "  1. Edit .env with Elastic Cloud credentials and OTLP endpoint"
echo "  2. cd vendor/elastic-opentelemetry-demo && docker compose up -d"
echo "  3. Confirm services in Kibana APM"
echo "  4. ./scripts/create-agent.sh   (or paste from docs/runbook.md)"
echo "  5. ./scripts/generate-traffic.sh"
echo "  6. Chat with bhargava-tutor in Kibana Agent Builder"
