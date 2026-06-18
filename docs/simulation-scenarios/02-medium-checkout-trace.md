# Scenario 2 — Checkout trace walkthrough (Medium)

**Persona:** Junior engineer who completed Scenario 1  
**Goal:** Follow one real Place Order request span-by-span through the distributed system  
**Duration:** ~25 minutes  
**Bhargava steps exercised:** Orient, Map, Walk trace, Quiz

---

## Learning objectives

By the end, the junior can:

- Retrieve a recent checkout trace from APM via Bhargava
- Narrate the request path in order (frontend → checkout → downstream)
- Read span duration and infer where latency accumulates
- Open a specific trace in Kibana Trace Explorer using Bhargava's link

---

## Setup (facilitator)

```bash
./scripts/generate-traffic.sh 5
```

Then in the browser:

1. Open [http://localhost:8080](http://localhost:8080)
2. Add **2 different products** to cart
3. Complete **Place Order** once
4. Wait 60 seconds for indexing

---

## Simulation script

### Prompt 1 — Set context

```
I just clicked "Place Order" in the Astronomy Shop a minute ago. Walk me through what happened behind the scenes using a real checkout trace from the last 30 minutes. Include Kibana links.
```

**Look for:** Bhargava method sections (Big picture, Trace walkthrough, Key concepts, Explore yourself, Check your understanding).

**Junior action:** Click the trace link. Confirm the trace ID in Kibana matches what Bhargava cited.

---

### Prompt 2 — Span detail

```
Go span by span on that trace like we're pair-programming. For each step tell me: service name, what it did, duration if available, and whether it called another service. Include the trace link again.
```

**Look for:** Numbered steps; no invented trace IDs; durations from tool data.

**Facilitator check:** Pick one span in Kibana and verify Bhargava's description matches the span name/operation.

---

### Prompt 3 — Latency focus

```
Which span or service took the longest in that trace? Why might that matter for a customer waiting at checkout?
```

**Look for:** Reasonable latency attribution (often payment, shipping quote, or fraud-detection); plain-English UX impact.

---

### Prompt 4 — Dependency drill-down

```
What happens inside checkout before payment is charged? Name the downstream services checkout calls and what each one contributes.
```

**Look for:** cart validation, currency conversion, fraud checks, shipping quotes — order may vary based on live trace.

---

### Prompt 5 — Trace vs service

```
What's the difference between the checkout *service* and the *trace* we just looked at? Give me a one-sentence answer and one Kibana link for each concept.
```

**Look for:** Service = always-on deployment; trace = one request instance; links to service overview + trace explorer.

---

### Prompt 6 — Quiz

```
Ask me two check-for-understanding questions about this checkout trace. I'll answer both, then tell me if I'm right.
```

**Junior:** Answer both questions before asking for grading.

**Sample questions Bhargava might ask:**

- "If payment were down, would the user still see a confirmation page?"
- "Which service would you inspect first for checkout slowness?"

---

## Success criteria

| Criterion | Pass |
|-----------|------|
| Bhargava used a real trace ID (verified in Kibana) | ☐ |
| Junior can recite path: frontend → checkout → ≥2 downstream | ☐ |
| Junior identified slowest span/service with justification | ☐ |
| Junior opened trace explorer and found ≥ 5 spans | ☐ |
| Junior answered ≥ 1 quiz question correctly | ☐ |

---

## Stretch goal

```
Show me trace metrics for checkout in the last 30 minutes — p95 latency and throughput if available.
```

**Look for:** `get_trace_metrics` usage; percentile numbers tied to checkout transactions.

---

## Common mistakes & hints

| Mistake | Hint |
|---------|------|
| Bhargava says no traces | Redo checkout; confirm APM shows checkout traces first |
| Junior treats all spans as sequential | Clarify: some spans are parallel (payment + shipping) |
| Overwhelmed by span count | Ask: "Summarize the top 5 spans only" |

---

## Debrief questions (facilitator)

1. Why is checkout an **orchestrator** rather than doing payment itself?
2. How would you find *another* checkout trace without Bhargava?
3. What is a **parent span** vs **child span** in the trace you saw?
