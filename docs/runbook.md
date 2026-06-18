# Hack Night Agent Builder Spec — Bhargava Junior Engineer Tutor

> **Project:** [`bhargava-junior-engineer-tutor/`](../README.md)

> **Use case:** A patient guru-agent named **Bhargava** (after Lord Parasurama) that onboards new hires to the OpenTelemetry **Astronomy Shop** using **real traces**, service topology, and Kibana deep links.
>
> **Wow moment:** "Explain this checkout trace" → step-by-step request journey + clickable trace IDs.
>
> **Time to deploy:** ~10 min once telemetry is flowing.

---

## Agent identity

| Field | Value |
|-------|-------|
| **ID** | `bhargava-tutor` |
| **Name** | Bhargava — Junior Engineer Tutor |
| **Description** | Named after Lord Parasurama (Bhargava). Onboards new engineers to the Astronomy Shop microservices architecture using live APM traces and Kibana. |
| **Avatar symbol** | `Bh` |
| **Avatar color** | `#FF9933` (saffron — guru / teacher) |

**Enable Elastic capabilities:** OFF — assign tools manually.

---

## Tools to assign

Prioritise **understanding** over **incident triage**:

```
observability.get_services
observability.get_service_topology
observability.get_downstream_dependencies
observability.get_traces
observability.get_trace_metrics
observability.search_logs
observability.get_correlated_logs
platform.core.execute_esql
platform.core.list_indices
```

Optional extras if available:
```
observability.get_log_patterns
observability.get_runtime_metrics
```

Drop change-point / alert tools — they distract from the tutoring narrative.

---

## Before you paste — set your Kibana base URL

Replace `YOUR_KIBANA_URL` below with your Elastic Cloud URL (no trailing slash), e.g.:
`https://my-deployment.kb.us-east-1.aws.elastic.cloud`

You'll embed this in the instructions so the agent generates **real Kibana links**.

---

Paste from [`agent/instructions.txt`](../agent/instructions.txt) or use `./scripts/create-agent.sh`.

---

## Demo questions (run in this order)

### 1. Warm-up — architecture overview
```
Bhargava, I'm a junior engineer starting today. Give me a tour of the Astronomy Shop — what services exist and how do they connect?
```

### 2. Core demo — trace walkthrough ⭐
```
I just clicked "Place Order" in the shop. Walk me through what happened behind the scenes using a real checkout trace from the last 30 minutes. Include Kibana links.
```

### 3. Wow moment — explain a specific trace
```
Find a recent checkout trace and explain it span by span like we're pair-programming. What would break if the payment service went down?
```

### 4. Follow-up — logs + traces
```
Show me how logs connect to that checkout trace. Where would I look in Kibana if checkout returned a 500?
```

### 5. Stretch — guru quiz
```
Bhargava, quiz me: ask me three questions about the Astronomy Shop architecture based on what we've explored. Then tell me if my answers are right.
```

---

## Pre-demo ritual (2 min)

1. Open Astronomy Shop → add 2 products → checkout once
2. Open Kibana → APM → confirm `checkout` and `frontend` have recent traces
3. Open Agent Builder → `bhargava-tutor`
4. Ask question **1** quietly while networking (pre-warms tools)
5. At lightning demo → question **2** live

---

## 5-minute lightning demo script

| Time | Say / Do |
|------|----------|
| 0:00 | "Day one at AstralMart. Kibana is open. No one explained checkout. So I built Bhargava — a guru tutor named after Parasurama, who taught through practice." |
| 0:30 | Show Astronomy Shop UI — click Place Order |
| 1:00 | Switch to Agent Builder → Bhargava |
| 1:15 | Ask: *"Walk me through what happened using a real checkout trace. Include Kibana links."* |
| 2:30 | Read the trace walkthrough aloud — **click a Kibana link live** to prove it's real |
| 3:30 | Show Service Map in Kibana matching what Bhargava described |
| 4:15 | "Bhargava turns live OpenTelemetry traces into onboarding — no runbook, no wiki, real data." |
| 4:45 | Mention stretch: guru quiz mode + correlated logs |

**Backup:** Pre-screenshot one Bhargava response with Kibana links on your phone.

---

## One-liner for judges

> "Bhargava is a junior-engineer tutor named after Lord Parasurama — powered by Elastic Agent Builder, it walks new hires through the Astronomy Shop using real traces and sends them straight into Kibana."

---

## API create (optional)

```bash
export KIBANA_URL="https://YOUR-KIBANA-URL"
export API_KEY="YOUR-API-KEY"

curl -X POST "${KIBANA_URL}/api/agent_builder/agents" \
  -H "Authorization: ApiKey ${API_KEY}" \
  -H "kbn-xsrf: true" \
  -H "Content-Type: application/json" \
  -d '{
    "id": "bhargava-tutor",
    "name": "Bhargava — Junior Engineer Tutor",
    "description": "Named after Lord Parasurama (Bhargava). Onboards new engineers to the Astronomy Shop using live APM traces and Kibana links.",
    "labels": ["hack-night", "onboarding", "opentelemetry", "bhargava"],
    "avatar_color": "#FF9933",
    "avatar_symbol": "Bh",
    "configuration": {
      "instructions": "PASTE FULL INSTRUCTIONS FROM ABOVE (with YOUR_KIBANA_URL replaced)",
      "tools": [{
        "tool_ids": [
          "observability.get_services",
          "observability.get_service_topology",
          "observability.get_downstream_dependencies",
          "observability.get_traces",
          "observability.get_trace_metrics",
          "observability.search_logs",
          "observability.get_correlated_logs",
          "platform.core.execute_esql",
          "platform.core.list_indices"
        ]
      }]
    }
  }'
```

---

## Why this wins vs on-call copilot

| On-call copilot | Bhargava tutor (your pick) |
|-----------------|----------------------------|
| Feels like every observability vendor demo | Memorable story: guru named after Parasurama teaches through real traces |
| Needs something broken | Works with **healthy** traces — less can go wrong |
| Technical audience only | Judges **and** non-experts understand it instantly |
| Hard to differentiate | Quiz mode + Kibana links = clear product vision |

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| No Kibana links in response | Re-paste instructions; emphasise "ALWAYS include markdown links" in your question |
| Agent too incident-focused | Add: "Teach me, don't triage. I'm learning, not on-call." |
| Trace walkthrough too shallow | Ask: "Go span by span with durations and Kibana links" |
| Wrong trace URL format | Click link yourself once; if 404, try `/app/apm/traces/{traceId}` instead of `explorer?traceId=` |
| Too much guru flavour | Add: "Keep the Parasurama references minimal — focus on the trace." |

---

## Pairing pitch

> "I'm building Bhargava — an onboarding guru over the OTel Astronomy Shop, named after Parasurama. Agent spec is ready; looking for someone on Docker while I demo trace walkthroughs in Kibana."
