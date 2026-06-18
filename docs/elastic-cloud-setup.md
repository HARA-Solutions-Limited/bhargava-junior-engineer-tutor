# Elastic Cloud setup — step-by-step

Configure Elastic Cloud so the Astronomy Shop sends OTLP telemetry and Bhargava can query it via Agent Builder.

**Time:** ~15 minutes (first time)

---

## Phase 1 — Create the Observability project

1. Go to [cloud.elastic.co](https://cloud.elastic.co) and sign in (or start a Serverless trial).
2. Click **Create project** → choose **Observability**.
3. Pick a **region** close to your laptop (lower latency for Kibana clicks during demos).
4. Name the project (e.g. `bhargava-hack-night`) and wait until status is **Healthy**.

You now have a Serverless Observability project with Kibana, Elasticsearch, and APM.

---

## Phase 2 — Get the Managed OTLP endpoint (mOTLP)

The Astronomy Shop sends traces, logs, and metrics to Elastic via the **Managed OTLP Endpoint**.

1. Open your Observability project in the Elastic Cloud console.
2. Go to **Add data** → **Applications** → **OpenTelemetry**.
3. Select **Managed OTLP Endpoint** (step 2 in the wizard).
4. Copy the **OTLP endpoint URL** — looks like:
   `https://<project-id>.ingest.<region>.aws.elastic.cloud:443`
5. Click **Create API Key** and copy the full auth header value:
   `Authorization=ApiKey <base64-key>`

Keep this tab open — you will paste these into local config files.

---

## Phase 3 — Create a Kibana API key for Bhargava

The `create-agent.sh` script needs a Kibana API key with Agent Builder permissions.

1. In Kibana, open **Stack Management** → **API keys** (or use the profile menu → **API keys**).
2. Click **Create API key**.
3. Name it `bhargava-agent-builder`.
4. Enable **Agent Builder** (and **Observability** read if offered as a role preset).
5. Copy the encoded key (`id:secret` format) — you only see it once.

Alternatively, use the Serverless **Management** → **API keys** with equivalent scopes.

---

## Phase 4 — Configure local `.env`

From the repo root:

```bash
./bootstrap.sh   # creates .env from .env.example if missing
```

Edit `.env`:

```bash
# Kibana — from project → Open Kibana (no trailing slash)
KIBANA_URL=https://YOUR-PROJECT.kb.REGION.cloud.es.io
KIBANA_BASE_URL=${KIBANA_URL}

# Elasticsearch — from project → Manage → Application endpoints
ELASTICSEARCH_URL=https://YOUR-PROJECT.es.REGION.cloud.es.io

# Agent Builder API key (Phase 3)
API_KEY=YOUR_KIBANA_API_KEY

# OTLP — from Add data → OpenTelemetry (Phase 2)
OTEL_EXPORTER_OTLP_ENDPOINT=https://YOUR-PROJECT.ingest.REGION.cloud.es.io:443
OTEL_EXPORTER_OTLP_HEADERS=Authorization=ApiKey YOUR_OTLP_API_KEY

SHOP_URL=http://localhost:8080
```

---

## Phase 5 — Point the Astronomy Shop at Elastic

After bootstrap clones the Elastic fork:

```bash
cd vendor/elastic-opentelemetry-demo
```

Create or edit `.env.override` (Elastic fork convention):

```bash
ELASTIC_OTLP_ENDPOINT="<same URL as OTEL_EXPORTER_OTLP_ENDPOINT>"
ELASTIC_OTLP_API_KEY="<same API key as in OTEL_EXPORTER_OTLP_HEADERS>"
```

Start the demo (follow the fork README — typically):

```bash
./demo.sh docker
# or: make start
```

Open the shop at [http://localhost:8080](http://localhost:8080).

---

## Phase 6 — Verify telemetry in Kibana

1. Browse the shop — add items to cart, click **Place Order** once.
2. In Kibana → **Observability** → **APM** → **Services**.
3. Confirm services appear within 1–2 minutes: `frontend`, `checkout`, `cart`, `payment`, etc.
4. Open **Traces** — filter `service.name: checkout` — you should see recent traces.

If services are missing after 5 minutes, check Docker logs for the otel-collector and verify `.env.override` credentials.

---

## Phase 7 — Deploy the Bhargava agent

```bash
cd ../..   # back to repo root
./scripts/create-agent.sh
```

This POSTs `bhargava-tutor` to Kibana Agent Builder with observability tools and your Kibana URL embedded in instructions.

1. In Kibana → **Agents** (Agent Builder) → confirm **Bhargava — Junior Engineer Tutor** exists.
2. Open a chat and ask: *"What services do you see in APM right now?"*

---

## Phase 8 — Generate training traffic

```bash
./scripts/generate-traffic.sh 10
```

Then manually complete one checkout in the browser (the script only hits the homepage/API).

---

## Configuration checklist

| Step | Done? |
|------|-------|
| Observability Serverless project healthy | ☐ |
| mOTLP endpoint + API key copied | ☐ |
| Kibana API key for Agent Builder | ☐ |
| `.env` filled in repo root | ☐ |
| `.env.override` filled in demo vendor dir | ☐ |
| Demo running (`localhost:8080`) | ☐ |
| APM services visible in Kibana | ☐ |
| `bhargava-tutor` agent created | ☐ |
| Test chat returns real service names | ☐ |

---

## Troubleshooting

| Symptom | Likely fix |
|---------|------------|
| No services in APM | Re-check `ELASTIC_OTLP_*` in `.env.override`; restart compose |
| Agent creation 403 | API key missing Agent Builder scope; create a new key |
| Bhargava invents trace IDs | No telemetry yet — checkout once, widen time window |
| Kibana links 404 | Verify `KIBANA_BASE_URL` has no trailing slash; try `/app/apm/traces/{id}` |
| Collector OOM | Allocate Docker ≥ 8 GB RAM for full demo stack |

---

## What stays in Elastic Cloud vs local

| Component | Where |
|-----------|-------|
| Astronomy Shop microservices | Local Docker |
| OTel Collector | Local Docker |
| Traces, logs, metrics storage | Elastic Cloud |
| Kibana APM UI | Elastic Cloud |
| Bhargava agent (Agent Builder) | Elastic Cloud |
