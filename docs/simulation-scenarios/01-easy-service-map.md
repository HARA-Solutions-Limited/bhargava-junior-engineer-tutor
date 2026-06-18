# Scenario 1 — Service map orientation (Easy)

**Persona:** Day-one junior engineer at AstralMart  
**Goal:** Understand what the Astronomy Shop is made of and where user traffic enters  
**Duration:** ~15 minutes  
**Bhargava steps exercised:** Orient, Map (partial)

---

## Learning objectives

By the end, the junior can:

- Name the user-facing entry service (`frontend`)
- Explain what `checkout` does in one sentence
- Open the Kibana Service Map and recognize 3+ downstream services
- Distinguish synthetic traffic (`load-generator`) from real user paths

---

## Setup (facilitator)

```bash
./scripts/generate-traffic.sh 3
```

No checkout required. Homepage traffic is enough for service discovery.

---

## Simulation script

Copy each prompt into Bhargava chat. Wait for a full response before the next prompt.

### Prompt 1 — Introduction

```
Hi Bhargava, I'm a junior engineer starting at AstralMart today. I haven't seen this codebase before. In plain English, what is the Astronomy Shop and why would we run it?
```

**Look for:** Brief e-commerce demo explanation; mention of microservices and OpenTelemetry.

---

### Prompt 2 — Service inventory

```
Give me a tour of all services you can see in APM right now. For each one, tell me its role in one line. Include a Kibana link to the service overview for checkout and frontend.
```

**Look for:** Tool use (`get_services`); table or list of services; working Kibana links.

**Junior action:** Click both links. Confirm they open APM service pages with recent data.

---

### Prompt 3 — Topology

```
Show me how the services connect — I'm trying to draw a mental map. Which services does checkout talk to directly? Include a link to the Service Map.
```

**Look for:** `get_service_topology` or `get_downstream_dependencies`; checkout → cart, payment, shipping, email, etc.

**Junior action:** Open Service Map link. Find `checkout` node and count its outbound edges.

---

### Prompt 4 — Entry point

```
If a customer clicks "Add to cart" in the browser, which service receives that request first? Don't walk a trace yet — just tell me the entry point and why.
```

**Look for:** `frontend` as HTTP entry; optional mention of `frontend-proxy`.

---

### Prompt 5 — Mini quiz

```
Quiz me with one question about what we covered. Keep it simple.
```

**Look for:** Bhargava's "Check your understanding" section with one question.

**Sample good answer:** "Frontend receives the browser request" or "Checkout orchestrates payment and shipping."

---

## Success criteria

| Criterion | Pass |
|-----------|------|
| Junior names `frontend` as entry point | ☐ |
| Junior explains checkout as orchestrator | ☐ |
| Junior opened ≥ 2 Kibana links successfully | ☐ |
| Junior listed ≥ 5 distinct services from Bhargava's answer | ☐ |
| Junior answered the quiz correctly | ☐ |

---

## Common mistakes & hints

| Mistake | Hint |
|---------|------|
| Confuses `load-generator` with real users | Ask Bhargava: "Ignore load-generator — what does a human user hit?" |
| Skips clicking links | Links prove the agent uses live data; clicking is part of the exercise |
| Wants trace detail too early | Save span-by-span for Scenario 2 |

---

## Debrief questions (facilitator)

1. Why do we prefer live APM over a static architecture diagram?
2. What's the difference between a **service** and a **trace**?
3. Where would you look tomorrow if someone said "checkout is slow"?
