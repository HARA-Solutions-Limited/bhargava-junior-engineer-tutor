# Bhargava — TLDR

**Bhargava** is an Elastic Agent Builder tutor named after Lord Parasurama (Bhargava). It onboards junior engineers to the **OpenTelemetry Astronomy Shop** using **live traces**, service topology, and **Kibana deep links** — not static wikis.

## Problem

New hires face a microservices e-commerce demo with 20+ services, mixed protocols (gRPC/HTTP), async Kafka paths, and rich telemetry. Traditional runbooks go stale; APM UIs overwhelm beginners.

## Solution

An AI agent (`bhargava-tutor`) configured in Kibana Agent Builder that:

1. Maps the live service graph
2. Pulls a real checkout trace
3. Walks the junior through span-by-span
4. Links directly into Kibana APM

## Stack

| Layer | Technology |
|-------|------------|
| Demo app | [OpenTelemetry Astronomy Shop](https://github.com/elastic/opentelemetry-demo) (Elastic fork) |
| Telemetry | OTLP traces, logs, metrics → Elastic Observability |
| AI tutor | Elastic Agent Builder (`bhargava-tutor`) |
| Runtime | Docker Compose locally; Elastic Cloud Serverless for observability |

## Core flow

```
Junior engineer → Bhargava chat → Observability tools → Elasticsearch APM data → Trace walkthrough + Kibana links
```

## Demo question

> *"I just clicked Place Order. Walk me through what happened using a real checkout trace. Include Kibana links."*

## Docs map

| Document | Purpose |
|----------|---------|
| [docs/requirements.md](docs/requirements.md) | EARS functional & non-functional requirements |
| [Architecture.md](Architecture.md) | C4 architecture + Astronomy Shop reverse engineering |
| [docs/hld.md](docs/hld.md) | High-level design and flows |
| [docs/lld.md](docs/lld.md) | Agent config, tools, API, response contract |
| [docs/runbook.md](docs/runbook.md) | Copy-paste hack-night runbook |
| [docs/elastic-cloud-setup.md](docs/elastic-cloud-setup.md) | Elastic Cloud + OTLP + Agent Builder setup |
| [docs/simulation-scenarios/](docs/simulation-scenarios/) | Easy / medium / hard junior training scenarios |
| [docs/uml/](docs/uml/) | C4 PlantUML, sequence, service topology diagrams |

## Quick start

```bash
./bootstrap.sh
cd vendor/elastic-opentelemetry-demo && docker compose up -d
./scripts/create-agent.sh
./scripts/generate-traffic.sh
```

Then chat with `bhargava-tutor` in Kibana Agent Builder.

## Why it wins

- Works with **healthy** traces (no need to break prod)
- Memorable **guru narrative** (Parasurama / teach through practice)
- **Clickable proof** — Kibana links validate the agent live
