# Simulation training scenarios

Three guided exercises for junior engineers using **Bhargava** and live Astronomy Shop telemetry. Each scenario maps to the [Bhargava method](../hld.md): Orient → Map → Walk trace → Connect logs → Quiz.

## Prerequisites

Complete [elastic-cloud-setup.md](../elastic-cloud-setup.md) and confirm APM shows `frontend` and `checkout` services.

## Scenarios

| # | Difficulty | Scenario | Time | Skills |
|---|------------|----------|------|--------|
| 1 | Easy | [Service map orientation](01-easy-service-map.md) | 15 min | APM services, topology, entry points |
| 2 | Medium | [Checkout trace walkthrough](02-medium-checkout-trace.md) | 25 min | Distributed traces, spans, Kibana links |
| 3 | Hard | [Checkout failure investigation](03-hard-checkout-debugging.md) | 40 min | Logs + traces, dependencies, blast radius |

## How to run a session

1. Facilitator generates traffic: `./scripts/generate-traffic.sh 5` + one manual checkout.
2. Junior opens **Agent Builder** → `bhargava-tutor`.
3. Junior copies prompts from the scenario doc **in order**.
4. Junior clicks every Kibana link Bhargava returns and verifies the answer.
5. Facilitator uses the **Success criteria** section to debrief.

## Facilitator tips

- Easy scenario needs no checkout trace — topology only.
- Medium and Hard require at least one checkout in the last 30 minutes.
- If Bhargava says "no traces," pause and checkout in the browser before continuing.
- Hard scenario works even when checkout is **healthy** — ask about hypothetical failures and dependency analysis.
