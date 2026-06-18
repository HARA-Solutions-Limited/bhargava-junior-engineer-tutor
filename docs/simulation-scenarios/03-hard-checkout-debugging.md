# Scenario 3 — Checkout failure investigation (Hard)

**Persona:** Junior engineer on first on-call shadow shift  
**Goal:** Investigate a checkout problem using traces, logs, dependencies, and blast-radius thinking — without Bhargava doing incident triage for you  
**Duration:** ~40 minutes  
**Bhargava steps exercised:** Full Bhargava method + correlated logs + ES|QL (optional)

---

## Learning objectives

By the end, the junior can:

- Correlate logs to a checkout trace time window
- Use downstream dependency data to explain blast radius
- Form a hypothesis when checkout returns errors (simulated or historical)
- Distinguish **teaching mode** from on-call triage and still extract useful investigation steps

---

## Setup (facilitator)

**Option A — Healthy stack (recommended for hack night)**

```bash
./scripts/generate-traffic.sh 10
# Complete 2 checkouts in the browser
```

Use **hypothetical failure** prompts — Bhargava analyzes real topology and traces, then reasons about what *would* break.

**Option B — Simulated failure (optional, advanced)**

If the demo supports feature flags via `flagd`, enable a payment or checkout fault per the Elastic fork docs, then complete a failing checkout. Skip this if unsure — Option A is sufficient.

---

## Simulation script

### Prompt 1 — Incident framing (teaching mode)

```
Teach me, don't triage — I'm learning how on-call investigation works. A user reported "Place Order failed with a 500." Walk me through how YOU would investigate this using traces and logs from the last 30 minutes. Start with a hypothesis and show me where to look in Kibana.
```

**Look for:** Structured investigation plan; checkout + frontend as starting services; links to APM and logs.

**Junior action:** Write down Bhargava's investigation steps before continuing.

---

### Prompt 2 — Find evidence

```
Find a recent checkout trace — successful or failed — and show me any error spans or HTTP 5xx signals. If everything looks healthy, pick the most recent checkout trace and show me what an error WOULD look like in the same span structure.
```

**Look for:** Honest handling of healthy data; `get_traces` with error filters if available.

---

### Prompt 3 — Logs correlation

```
Connect logs to that checkout trace. Use correlated logs or log search — show me what log fields would prove payment failed vs cart failed. Include Kibana links or index names.
```

**Look for:** `get_correlated_logs` or `search_logs`; mention of `service.name`, `trace.id`, log level ERROR.

**Junior action:** In Kibana Logs, filter `service.name: checkout` and `log.level: error` for the same time window.

---

### Prompt 4 — Blast radius

```
If the payment service went completely down, which upstream services and user-facing features would be affected? Use downstream dependency data and explain the blast radius.
```

**Look for:** `get_downstream_dependencies` or topology in reverse; frontend/checkout impact; cart unaffected for browsing.

---

### Prompt 5 — Metrics layer

```
What trace metrics do you see for payment and checkout in the last 30 minutes? Are there latency spikes or error rate changes that would support a payment outage theory?
```

**Look for:** `get_trace_metrics`; p95 latency, throughput, failed transaction rate if present.

---

### Prompt 6 — ES|QL deep dive (optional stretch)

```
Use ES|QL to find the 5 slowest checkout spans in the last 30 minutes. Show me the query and summarize what you find.
```

**Look for:** `platform.core.execute_esql`; query against APM span indices; slow span names.

---

### Prompt 7 — Runbook draft

```
Based on everything we explored, draft a 5-step runbook snippet a junior could follow when checkout returns 500. Keep it specific to the Astronomy Shop services we have in APM.
```

**Look for:** Actionable steps: confirm trace, check payment/cart logs, service map, rollback/feature flag mention, escalate.

---

### Prompt 8 — Final exam

```
Quiz me with three questions: one on traces, one on logs, one on blast radius. I want to prove I could shadow on-call tomorrow.
```

**Junior:** Answer all three before requesting grading.

---

## Success criteria

| Criterion | Pass |
|-----------|------|
| Junior documented ≥ 4 investigation steps from Prompt 1 | ☐ |
| Junior opened logs view filtered by checkout service | ☐ |
| Junior explained blast radius: payment down → checkout/frontend fail, browse may work | ☐ |
| Junior cited ≥ 1 trace metric (latency, throughput, or error rate) | ☐ |
| Junior's runbook mentions checking payment AND cart | ☐ |
| Junior scored ≥ 2/3 on final quiz | ☐ |

---

## Grading rubric (facilitator)

| Answer quality | Score |
|----------------|-------|
| Names correct services + Kibana destination | 1 pt |
| Uses trace/log correlation concept correctly | 1 pt |
| Identifies user-visible symptom (order fails, no email) | 1 pt |

**Pass:** ≥ 5/6 success criteria + ≥ 2/3 quiz points

---

## Common mistakes & hints

| Mistake | Hint |
|---------|------|
| Bhargava switches to full incident mode | Repeat: "Teach me, don't triage — I'm learning" |
| Junior jumps to payment without checking checkout trace | Remind: always anchor on one trace ID first |
| No errors in environment | Frame as **tabletop exercise** — grade the investigation process, not a live outage |
| ES|QL fails | Fall back to Trace Explorer sort-by-duration manually |

---

## Debrief questions (facilitator)

1. What's the first signal you'd check: logs, metrics, or traces? Why?
2. How does `trace.id` link logs and spans?
3. Could the shop still show products if payment was down? Which services prove it?

---

## Tabletop answer key (when stack is healthy)

Use this if no real 500s exist:

| Failure | User symptom | First Kibana stop | Upstream impact |
|---------|--------------|-------------------|-----------------|
| `payment` down | Place Order fails | APM → payment → failed transactions | `checkout`, `frontend` |
| `cart` down | Cannot add items | APM → cart errors | `frontend`, blocks checkout |
| `shipping` down | Checkout may fail or skip delivery options | Trace span on shipping quote | `checkout` orchestration fails |
| `email` down | Order succeeds, no confirmation email | Logs in `email` service | No user-blocking path |
