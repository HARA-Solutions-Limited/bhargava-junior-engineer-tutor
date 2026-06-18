# Bhargava hackathon sprint plan — 1 hour, 2 people

**Team:** [Alapaty](https://www.linkedin.com/in/alapaty/) + [Laxman Peri](https://www.linkedin.com/in/laxman-peri/)  
**Clock time:** 60 minutes (2 × 30 min sprints)  
**Goal:** Live end-to-end demo — Astronomy Shop → Elastic APM → Bhargava trace walkthrough with clickable Kibana links

> One hour is tight. **Do the pre-work below before the clock starts** or you will spend the whole hour on Docker pulls and API keys.

---

## Pre-hackathon (before T+0 — not counted in the hour)

| Who | Task | Why |
|-----|------|-----|
| **Both** | Clone repo, `./bootstrap.sh`, Docker Desktop running (≥ 8 GB RAM) | Avoid clone/pull during the hour |
| **Laxman** | Elastic Cloud Observability project **Healthy**; mOTLP endpoint + API key copied | Longest external dependency |
| **Alapaty** | Kibana API key with **Agent Builder** scope; `.env` drafted (no secrets in git) | Unblocks `create-agent.sh` |
| **Both** | Read [runbook.md](runbook.md) demo question #2 + 5-min lightning script | Shared demo script |

**Pre-work exit criteria:** You have 4 values on a shared note — `KIBANA_URL`, `API_KEY`, `OTEL endpoint`, `OTLP API key`.

---

## Role split (parallel by default)

| Track | **Laxman Peri** — Platform / telemetry | **Alapaty** — Agent / demo |
|-------|----------------------------------------|----------------------------|
| Owns | Elastic Cloud, Docker demo, OTLP, APM proof | Bhargava agent, prompts, demo narrative, Kibana links |
| Success signal | `frontend` + `checkout` in APM with recent traces | Bhargava returns real trace ID + working Kibana link |

**Comms:** 5-min sync at **T+25** and **T+55**. Slack/WhatsApp: “APM green” / “Agent green”.

---

## Block 1 — T+0 → T+30 | “Make data flow”

### Laxman (P0 — nothing else matters until this works)

| Min | Task | Exit criteria |
|-----|------|---------------|
| 0–5 | `./bootstrap.sh`; fill `vendor/elastic-opentelemetry-demo/.env.override` with `ELASTIC_OTLP_ENDPOINT` + `ELASTIC_OTLP_API_KEY` | File saved |
| 5–20 | Start demo: `cd vendor/elastic-opentelemetry-demo && ./demo.sh docker` (or `make start`) | `localhost:8080` loads |
| 20–25 | `./scripts/generate-traffic.sh 5` + **one manual checkout** (2 products) | Order completes in UI |
| 25–30 | Kibana → APM → Services: confirm `frontend`, `checkout`, `cart`, `payment` | Screenshot → Alapaty |

**If stuck:** Collector logs first; re-check `.env.override` credentials. Do **not** debug Agent Builder until APM shows services.

---

### Alapaty (P0 — agent ready when traces land)

| Min | Task | Exit criteria |
|-----|------|---------------|
| 0–10 | Complete `.env` (`KIBANA_URL`, `API_KEY`); run `./scripts/create-agent.sh` | Agent appears in Kibana Agent Builder |
| 10–15 | Open `bhargava-tutor` → ask: *“What services do you see in APM?”* | Returns **real** service names (not invented) |
| 15–25 | If no services yet: run warm-up prompt from [runbook](runbook.md) anyway; fix agent/tools if 403 or empty tools | Tools assigned; chat works |
| 25–30 | Pre-open tabs: Shop `:8080`, Kibana APM Services, Agent Builder chat, Service Map | Demo layout ready |

**If stuck:** API key missing Agent Builder scope → recreate key. Agent conflict → check Kibana UI for existing `bhargava-tutor`.

---

### Block 1 team checkpoint (T+25)

| Gate | Pass? |
|------|-------|
| APM shows ≥ 5 services | ☐ |
| ≥ 1 checkout trace in last 30 min | ☐ |
| `bhargava-tutor` chat responds with real data | ☐ |

**If only 2/3 pass at T+30:** Skip Block 2 stretch goals; both focus on the failed gate.

---

## Block 2 — T+30 → T+60 | “Prove the wow moment”

### Both together (T+30–T+45) — E2E validation

| Min | Task | Who leads |
|-----|------|-----------|
| 30–32 | Fresh checkout in browser | Laxman |
| 32–40 | Alapaty asks **core demo question** in Agent Builder | Alapaty |

```
I just clicked "Place Order" in the shop. Walk me through what happened behind the scenes using a real checkout trace from the last 30 minutes. Include Kibana links.
```

| 40–45 | **Click a Kibana trace link live** — must open Trace Explorer with matching trace ID | Alapaty clicks, Laxman confirms in APM |

**Fix loop (max 10 min):**

| Issue | Owner | Fix |
|-------|-------|-----|
| No traces in response | Laxman | Another checkout + wait 60s |
| Broken Kibana link 404 | Alapaty | Fix `KIBANA_BASE_URL` (no trailing slash); re-run `create-agent.sh` |
| Shallow walkthrough | Alapaty | Add: *“Go span by span with durations and Kibana links”* |
| Agent triage mode | Alapaty | Add: *“Teach me, don't triage. I'm learning.”* |

---

### Split rehearsal (T+45–T+55)

| Who | Task |
|-----|------|
| **Alapaty** | Run full [5-minute lightning demo script](runbook.md) once, aloud, with live clicks |
| **Laxman** | Run [Scenario 1 easy](simulation-scenarios/01-easy-service-map.md) Prompt 2 as backup demo if trace walkthrough fails |

**Backup artifact:** Screenshot one good Bhargava response with Kibana links (phone).

---

### Final polish (T+55–T+60)

| Min | Task | Owner |
|-----|------|-------|
| 55–57 | Second checkout + traffic script `generate-traffic.sh 3` | Laxman |
| 57–59 | One quiet warm-up question in Bhargava (runbook #1) | Alapaty |
| 59–60 | Agree handoff: who drives demo, who drives Docker if judges ask | Both |

---

## Definition of “successful hackathon” (minimum viable)

1. Shop running locally
2. Live telemetry in Elastic APM
3. Bhargava answers checkout trace question with **real trace ID**
4. **One Kibana link clicked live** and opens correct trace
5. 5-minute demo rehearsed once

---

## Priority stack (if time runs out)

| Priority | Task | Drop if needed |
|----------|------|----------------|
| **P0** | OTLP → APM services visible | — |
| **P0** | `bhargava-tutor` created + tools work | — |
| **P0** | Core demo question + live link click | — |
| **P1** | 5-min lightning rehearsal | Scenario 1 backup only |
| **P1** | Service Map shown during demo | Mention verbally |
| **P2** | Scenario 2 medium / quiz mode | Post-hackathon |
| **P2** | Custom ES\|QL tool, MCP | Never in 1-hour window |

---

## Optional second hour (if you get more stage time)

| Block | Focus |
|-------|--------|
| **T+60–T+90** | [Scenario 2 medium](simulation-scenarios/02-medium-checkout-trace.md) + logs prompt (runbook #4) |
| **T+90–T+120** | [Scenario 3 hard](simulation-scenarios/03-hard-checkout-debugging.md) tabletop + judge Q&A prep |

---

## One-liner division for introductions

> **Laxman** wires the Astronomy Shop to Elastic Cloud so every checkout becomes a live trace. **Alapaty** built Bhargava — a guru tutor in Agent Builder that walks juniors through those traces and drops them straight into Kibana.
