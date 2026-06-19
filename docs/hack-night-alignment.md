# Hack Night Alignment — Bhargava × DevOps Society

This project implements the [DevOps Society × Elastic London Hack Night](https://github.com/carlyrichmond/devops-society-elastic-hack-night) requirements **through Bhargava** — a custom Agent Builder tutor that goes beyond the default agent with a live trace walkthrough demo.

---

## How Bhargava maps to the official hack night

| Official hack night requirement | Bhargava implementation | Status |
|--------------------------------|-------------------------|--------|
| Elastic Serverless Observability trial | `.env` → `KIBANA_URL`, `ELASTICSEARCH_URL` | Configure in Elastic Cloud |
| Elasticsearch + Kibana API keys | `.env` → `API_KEY` (Agent Builder) + OTLP key in headers | **You must paste real keys** |
| Fork Elastic OTel demo | `vendor/elastic-opentelemetry-demo` via `./bootstrap.sh` | Done |
| `.env.override` with mOTLP endpoint | Synced by `./scripts/start-demo.sh` from root `.env` | Done when `.env` correct |
| `transform/logs-streams` processor | `config/otelcol-elastic-hacknight.yaml` | Done |
| Start demo app | **Docker:** `./scripts/start-demo.sh` · **K8s (official):** see below | Docker recommended |
| Browse APM / Discover / Traces | Kibana Observability — see [tasks below](#elastic-observability-tasks) | After OTLP works |
| Create custom Agent Builder agent | `./scripts/create-agent.sh` → `bhargava-tutor` | After `API_KEY` works |
| Ask agent about telemetry | Bhargava demo questions in [runbook.md](runbook.md) | After agent + APM |
| Elastic Observability MCP (stretch) | Optional — [example MCP app](https://github.com/elastic/example-mcp-app-observability) | P2 |

**Bhargava adds (novel angle for prizes):** a guru tutor that walks juniors through **real checkout traces** with **clickable Kibana links** — not just querying metrics.

---

## One-command flow (Docker — our path)

```bash
chmod +x bootstrap.sh scripts/*.sh
./scripts/hack-night-complete.sh
```

Or step by step:

```bash
./bootstrap.sh
# Edit .env — see "Credentials" below
./scripts/start-demo.sh
./scripts/verify-setup.sh
./scripts/create-agent.sh
./scripts/generate-traffic.sh 10
./scripts/place-order.sh
```

---

## Credentials (from Elastic Cloud)

Follow the [official cluster setup](https://github.com/carlyrichmond/devops-society-elastic-hack-night#cluster-setup) and [Elastic API keys guide](https://www.elastic.co/docs/deploy-manage/api-keys/elasticsearch-api-keys).

### 1. OTLP ingest (telemetry → Elastic)

Elastic Cloud → **Add data** → **Applications** → **OpenTelemetry** → **Managed OTLP Endpoint**

Copy into root `.env`:

```bash
OTEL_EXPORTER_OTLP_ENDPOINT=https://YOUR-PROJECT.ingest.REGION.cloud.elastic.cloud:443
OTEL_EXPORTER_OTLP_HEADERS="Authorization=ApiKey YOUR_OTLP_ENCODED_KEY"
```

Example format from hack night repo:

```bash
ELASTIC_OTLP_ENDPOINT="https://my-cluster.ingest.northeurope.azure.elastic.cloud:443"
ELASTIC_OTLP_API_KEY="MyRandomAPIKey"
```

> **Important:** The hostname must resolve. If you see `NXDOMAIN` in collector logs, the ingest URL is wrong — re-copy from Elastic Cloud (not from Kibana/ES URLs).

### 2. Kibana API key (Agent Builder)

Kibana → **Admin and Settings** → **API keys** → Create with **Agent Builder** scope.

Paste the **full encoded key** (`id:secret` base64, no spaces) into `.env`:

```bash
API_KEY=your_full_encoded_key_here
```

---

## Docker vs Kubernetes

| | **Official hack night** | **Bhargava (this repo)** |
|---|-------------------------|--------------------------|
| Runtime | `minikube` + `./demo.sh k8s` | Docker + `./scripts/start-demo.sh` |
| Port forward | `kubectl port-forward svc/frontend-proxy 8080:8080` | `localhost:8080` direct |
| K8s dashboards (pod count) | Yes — pre-loaded | N/A on Docker; use APM Service Map instead |
| Demo agent story | Generic custom agent | **Bhargava** trace tutor |

### Optional: official K8s path

If judges expect the exact hack night setup:

```bash
cd vendor/elastic-opentelemetry-demo
# Edit .env.override with ELASTIC_OTLP_* (same values as .env)
minikube start
./demo.sh k8s
kubectl --namespace default port-forward svc/frontend-proxy 8080:8080
```

Add the logs-streams processor manually to the k8s collector config (same YAML as in `config/otelcol-elastic-hacknight.yaml`).

Then deploy Bhargava from repo root: `./scripts/create-agent.sh`

---

## Elastic Observability tasks

From the [hack night Observability section](https://github.com/carlyrichmond/devops-society-elastic-hack-night#elastic-observability):

| Task | How to complete with Bhargava |
|------|-------------------------------|
| **2.1** Error for a `service.name` in Discover | Kibana → Discover → filter `service.name: checkout` + `log.level: error` (or use Bhargava: *"Show me errors for checkout in the last 15 minutes"*) |
| **2.2** Trace through `frontend-proxy` | Kibana → APM → Traces → filter `service.name: frontend-proxy` after `./scripts/place-order.sh` |
| **2.3** Running pods (K8s dashboards) | K8s path only; on Docker use APM **Service Map** instead |

---

## Agent Builder tasks

From the [hack night Agent Builder section](https://github.com/carlyrichmond/devops-society-elastic-hack-night#elastic-agent-builder):

| Official question | Bhargava equivalent |
|-------------------|---------------------|
| Number of running pods | *"How many Kubernetes pods are running?"* (K8s only) · Docker: *"What services do you see in APM?"* |
| Errors in last 15 minutes | *"How many errors have we seen in the last 15 minutes?"* |
| Build dashboards via NL | Stretch — mention in demo |
| Service dependencies | **Core demo:** *"Walk me through a checkout trace span by span. Include Kibana links."* |

### Core Bhargava demo (your differentiator)

```
I just clicked "Place Order" in the shop. Walk me through what happened behind the scenes using a real checkout trace from the last 30 minutes. Include Kibana links.
```

Click a Kibana link live to prove it's real data.

---

## Completion checklist

### Hack night minimum (official)

- [ ] Elastic Serverless Observability project healthy
- [ ] OTLP endpoint + API key in `.env` / `.env.override`
- [ ] Demo running (`localhost:8080`)
- [ ] Services visible in Kibana APM
- [ ] Custom agent in Agent Builder
- [ ] Answered at least one observability question with real data

### Bhargava minimum (your project)

- [ ] `./scripts/verify-setup.sh` — all gates green
- [ ] `bhargava-tutor` created via `./scripts/create-agent.sh`
- [ ] Checkout trace walkthrough with real trace ID
- [ ] Kibana link clicked live during demo
- [ ] 5-minute lightning script rehearsed ([runbook.md](runbook.md))

Run `./scripts/verify-setup.sh` anytime to see which gates pass.

---

## What's next (stretch — hack night "What's next?")

| Stretch goal | Bhargava path |
|--------------|---------------|
| Alerts | Kibana or Elastic Observability MCP |
| Custom MCP + GitHub tools | [example MCP app](https://github.com/elastic/example-mcp-app-observability) |
| Anomaly detection | Kibana ML |
| Wired Streams | Already wired via `transform/logs-streams` in our collector config |
| Wild ideas | Guru quiz mode, ES\|QL slow-checkout tool — see [implementation-tasks.md](implementation-tasks.md) P2 |

---

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `NXDOMAIN` on ingest hostname | Re-copy **Managed OTLP** URL from Elastic Cloud. On GCP Serverless, if `*.ingest.*.gcp.elastic.cloud` fails, try your **Elasticsearch** project URL (`*.es.*.gcp.elastic.cloud`) — run `./scripts/validate-otlp.sh` |
| Collector HTTP 401 | OTLP API key is wrong — copy the **full encoded** key from Add data → OpenTelemetry (not a fragment) |
| Agent create 401 | Use full encoded API key; enable Agent Builder scope |
| Shop 000 / proxy restarting | `./scripts/start-demo.sh` (applies Bhargava compose fixes) |
| Checkout 500 | Shipping crash — fixed by `FLAGD_*` in `config/docker-compose.bhargava-fix.yml` |
| No traces in Bhargava | `./scripts/place-order.sh` then wait 60s |

---

## References

- [Hack night repo](https://github.com/carlyrichmond/devops-society-elastic-hack-night)
- [Elastic mOTLP quickstart](https://www.elastic.co/docs/solutions/observability/get-started/quickstart-elastic-cloud-otel-endpoint)
- [Bhargava sprint plan](hackathon-sprint-plan.md)
- [Bhargava runbook](runbook.md)
