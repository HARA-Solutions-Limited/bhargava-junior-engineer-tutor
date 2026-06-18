# Low-Level Design — Bhargava

## Agent specification

| Property | Value |
|----------|-------|
| Agent ID | `bhargava-tutor` |
| Display name | Bhargava — Junior Engineer Tutor |
| Avatar | `Bh` / `#FF9933` |
| Elastic capabilities toggle | OFF (manual tools) |
| Default lookback | 30 minutes |

Full copy-paste runbook: [runbook.md](runbook.md)

## Tool assignments

### Primary observability tools

| Tool ID | LLD usage |
|---------|-----------|
| `observability.get_services` | Step 2 Map — list APM services, health |
| `observability.get_service_topology` | Step 2 Map — dependency graph + RED metrics |
| `observability.get_downstream_dependencies` | Blast radius / dependency teaching |
| `observability.get_traces` | Step 3 Walk — fetch trace documents by ID/window |
| `observability.get_trace_metrics` | Latency percentiles per service/transaction |
| `observability.search_logs` | Step 4 Connect — log search with histogram |
| `observability.get_correlated_logs` | Logs tied to trace/time window |

### Platform tools

| Tool ID | LLD usage |
|---------|-----------|
| `platform.core.execute_esql` | Ad-hoc queries (slow checkout spans) |
| `platform.core.list_indices` | Discover APM/log index patterns |

### Optional

| Tool ID | LLD usage |
|---------|-----------|
| `observability.get_log_patterns` | Log category teaching |
| `observability.get_runtime_metrics` | JVM/runtime lesson extension |

## Instruction contract

### Persona

- Name: **Bhargava** (after Lord Parasurama)
- Tone: patient guru — precise, encouraging, brief Parasurama framing
- Fictional employer context: **AstralMart** runs the Astronomy Shop

### Bhargava method (ordered steps)

```
1. Orient      → parse user intent
2. Map         → get_services + get_service_topology
3. Walk trace  → get_traces (prefer checkout)
4. Connect logs → search_logs | get_correlated_logs
5. Quiz        → one comprehension question
```

### Response schema

```markdown
### 🗺️ Big picture
### 🚶 Trace walkthrough   (numbered, with Kibana links per step)
### 💡 Key concepts
### 🔗 Explore yourself
### ❓ Check your understanding
```

### Kibana URL templates

Replace `YOUR_KIBANA_URL` at agent creation time.

| Asset | Template |
|-------|----------|
| Trace | `{BASE}/app/apm/traces/explorer?traceId={trace.id}` |
| Service | `{BASE}/app/apm/services/{service.name}/overview` |
| Service map | `{BASE}/app/apm/services?comparisonEnabled=true` |

**Fallback** if explorer URL 404s: `{BASE}/app/apm/traces/{traceId}`

## Astronomy Shop — LLD service reference

Used in agent instructions (static fallback when tools empty).

| service.name (APM) | Protocol | Upstream callers | Downstream deps |
|--------------------|----------|------------------|-----------------|
| frontend | HTTP/gRPC | frontend-proxy | checkout, cart, catalog, … |
| checkout | gRPC/HTTP/Kafka | frontend | cart, payment, shipping, email, currency, product-catalog, Kafka |
| payment | gRPC | checkout | flagd |
| cart | gRPC | frontend, checkout | Valkey, flagd |
| shipping | HTTP/gRPC | frontend, checkout | quote |
| product-catalog | gRPC | frontend, checkout, recommendation | — |
| email | HTTP | checkout | — |
| currency | gRPC | frontend, checkout | — |
| fraud-detection | Kafka/gRPC | queue | flagd |
| accounting | Kafka | queue | PostgreSQL |

## Sequence — checkout tutoring session

See [sequence-tutor-session.puml](uml/sequence-tutor-session.puml).

```
Junior → Agent Builder: "Explain my Place Order click"
Agent → get_services: last 30m
Agent → get_traces: filter checkout/frontend
Agent → get_service_topology: checkout deps
Agent → search_logs: correlated errors (optional)
Agent → Junior: formatted walkthrough + Kibana links
Junior → Kibana APM: validates trace link
```

## API — programmatic agent creation

```http
POST /api/agent_builder/agents
Header: kbn-xsrf: true
Header: Authorization: ApiKey {key}
```

```json
{
  "id": "bhargava-tutor",
  "name": "Bhargava — Junior Engineer Tutor",
  "configuration": {
    "instructions": "<full instructions with KIBANA_URL>",
    "tools": [{ "tool_ids": ["observability.get_services", "..."] }]
  }
}
```

## Data accessed (read-only)

| Elasticsearch data stream / index | Content |
|-----------------------------------|---------|
| `traces-apm*` | Span documents, trace.id, service.name, duration |
| `logs-*` | Structured application logs |
| APM aggregations | Service metrics, dependency graphs |

Bhargava does **not** write to shop databases (PostgreSQL, Valkey, Kafka).

## Error handling

| Condition | Agent behaviour |
|-----------|-----------------|
| No traces in window | Instruct user to browse localhost:8080 and checkout |
| Tool timeout | Report missing data; suggest wider window |
| Unknown service | Fall back to get_services list |
| User asks incident triage | Redirect: "I'm in teaching mode — want a walkthrough instead?" |

## Configuration checklist

- [ ] `YOUR_KIBANA_URL` replaced in instructions
- [ ] Elastic Cloud Observability project live
- [ ] OTel demo exporting to Elastic (verify APM services)
- [ ] Agent tools assigned (or Elastic capabilities ON as fallback)
- [ ] Test question asked before lightning demo

## Project layout

```
bhargava-junior-engineer-tutor/
├── README.md
├── TLDR.md
├── Architecture.md
├── bootstrap.sh
├── agent/
│   ├── instructions.txt
│   └── bhargava-tutor-agent.json
├── scripts/
│   ├── create-agent.sh
│   └── generate-traffic.sh
└── docs/
    ├── requirements.md
    ├── hld.md
    ├── lld.md
    ├── runbook.md
    └── uml/
```

## Future work

| Item | Priority |
|------|----------|
| Custom ES\|QL tool `hack.slow_checkout_transactions` | P2 |
| Agent Builder Skill with quiz question bank | P2 |
| On-call copilot variant (swap tools + instructions) | P3 |
| MCP integration for Claude Code | P3 |

See [implementation-tasks.md](implementation-tasks.md) for Bhargava roadmap.
