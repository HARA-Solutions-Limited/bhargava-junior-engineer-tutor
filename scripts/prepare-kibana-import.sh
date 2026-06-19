#!/usr/bin/env bash
# Build Kibana UI import helper when API key is unavailable.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

# shellcheck disable=SC1091
source .env 2>/dev/null || true
KIBANA_BASE_URL="${KIBANA_BASE_URL:-${KIBANA_URL:-YOUR_KIBANA_URL}}"

python3 - "${ROOT_DIR}/agent/instructions.txt" "${KIBANA_BASE_URL}" "${ROOT_DIR}/agent/bhargava-ui-import.txt" <<'PY'
import sys
instructions_path, kibana_url, out_path = sys.argv[1:4]
instructions = open(instructions_path).read().replace("YOUR_KIBANA_URL", kibana_url.rstrip("/"))
out = f"""# Create Bhargava manually in Kibana Agent Builder

1. Open: {kibana_url}/app/agent_builder
2. Click **Create agent**
3. Fill in:
   - **ID:** bhargava-tutor
   - **Name:** Bhargava — Junior Engineer Tutor
   - **Description:** Named after Lord Parasurama (Bhargava). Onboards new engineers to the Astronomy Shop using live APM traces and Kibana links.
   - **Avatar symbol:** Bh
   - **Avatar color:** #FF9933
4. **Disable** "Enable Elastic capabilities" — assign tools manually
5. Assign these tools:
   - observability.get_services
   - observability.get_service_topology
   - observability.get_downstream_dependencies
   - observability.get_traces
   - observability.get_trace_metrics
   - observability.search_logs
   - observability.get_correlated_logs
   - platform.core.execute_esql
   - platform.core.list_indices
6. Paste the instructions below into the agent instructions field:

--- INSTRUCTIONS START ---
{instructions}
--- INSTRUCTIONS END ---

7. Save, then ask the core demo question:
   "I just clicked Place Order. Walk me through what happened using a real checkout trace from the last 30 minutes. Include Kibana links."
"""
open(out_path, "w").write(out)
print(f"Wrote {out_path}")
PY

open "${KIBANA_BASE_URL}/app/agent_builder" 2>/dev/null || true
echo "Open agent/bhargava-ui-import.txt and follow the steps."
