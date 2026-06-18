# High-Level Design — Bhargava

## Objective

Deliver an AI-powered **junior engineer tutor** that teaches the OpenTelemetry **Astronomy Shop** architecture through **live observability data**, using Elastic Agent Builder and the **Bhargava** persona (named after Lord Parasurama — teaching through practice, not theory).

## Problem statement

The Astronomy Shop is a realistic but complex microservices demo (~20 services, gRPC/HTTP/Kafka). Junior engineers struggle to connect user actions (e.g. checkout) to distributed traces. Static docs diverge from live behaviour.

## Solution overview

Configure a custom Agent Builder agent (`bhargava-tutor`) with observability tools and structured instructions. The agent queries Elastic APM for real traces and topology, then returns pedagogical walkthroughs with Kibana deep links.

## High-level flows

### 1. Telemetry bootstrap

1. Operator starts Astronomy Shop via Docker Compose (Elastic fork).
2. Microservices emit OTLP to the collector.
3. Collector exports to Elastic Cloud Observability.
4. Operator confirms services appear in Kibana APM.

### 2. Tutoring session (Bhargava method)

1. **Orient** — clarify the junior's question.
2. **Map** — `get_services` + `get_service_topology` for system context.
3. **Walk the trace** — `get_traces` for a real checkout example; span-by-span narration.
4. **Connect logs** — `search_logs` / `get_correlated_logs` for supporting evidence.
5. **Quiz** — one check-for-understanding question.

### 3. Demo / hack-night flow

1. Generate traffic (browse + checkout at `:8080`).
2. Open Agent Builder → `bhargava-tutor`.
3. Ask trace walkthrough question with Kibana links.
4. Click link to validate live in APM Service Map / Trace Explorer.

## Logical architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Presentation                             │
│  Kibana Agent Builder Chat  │  Kibana APM UI (linked)        │
└─────────────────────────────┬───────────────────────────────┘
                              │
┌─────────────────────────────▼───────────────────────────────┐
│                     Bhargava Agent                           │
│  Instructions │ Tool orchestration │ Response formatting    │
└─────────────────────────────┬───────────────────────────────┘
                              │ observability.* / platform.core.*
┌─────────────────────────────▼───────────────────────────────┐
│                  Elastic Observability                       │
│  APM traces │ Logs │ Metrics │ Service map │ ES|QL          │
└─────────────────────────────▲───────────────────────────────┘
                              │ OTLP
┌─────────────────────────────┴───────────────────────────────┐
│              Astronomy Shop + OTel Collector                 │
│  frontend → checkout → payment/cart/shipping/...           │
└─────────────────────────────────────────────────────────────┘
```

## Astronomy Shop — reverse-engineered summary

| Domain | Services |
|--------|----------|
| Edge | frontend-proxy, frontend, image-provider |
| Catalog | product-catalog, product-reviews, recommendation |
| Commerce | cart, checkout, payment, currency |
| Fulfilment | shipping, quote, email |
| Risk & finance | fraud-detection, accounting |
| Platform | flagd, ad, llm, load-generator |
| Data | Valkey (cache), Kafka (queue), PostgreSQL (DB) |

**Primary teaching trace:** user checkout via `frontend` → `checkout` → downstream gRPC/HTTP calls.

Detailed topology: [Architecture.md](../Architecture.md) · [astronomy-shop-services.puml](uml/astronomy-shop-services.puml)

## Runtime environment

| Component | Runtime |
|-----------|---------|
| Astronomy Shop | Docker Compose (local) or Kubernetes/minikube |
| OTel Collector | Sidecar stack in demo compose |
| Elastic Observability | Elastic Cloud Serverless (hack night) |
| Bhargava agent | Kibana Agent Builder |
| Optional MCP | Claude Code + Elastic Observability MCP |

## Key design decisions

| Decision | Rationale |
|----------|-----------|
| Tutor over on-call copilot | Works with healthy traces; clearer demo narrative |
| Named persona (Bhargava) | Memorable; guru-teaching metaphor |
| Manual tool assignment | Predictable demo; fewer surprise tool calls |
| Kibana links in responses | Proves agent output; junior can self-explore |
| 30-minute default window | Enough traces after light traffic |
| Elastic fork of OTel demo | Native OTLP → Elastic integration |

## Non-goals

- Modifying Astronomy Shop source for custom spans
- Building a standalone web app outside Kibana
- Replacing Elastic documentation or formal training programmes

## Related documents

- [TLDR.md](TLDR.md)
- [requirements.md](requirements.md)
- [Architecture.md](../Architecture.md)
- [lld.md](lld.md)
- [runbook.md](runbook.md)
