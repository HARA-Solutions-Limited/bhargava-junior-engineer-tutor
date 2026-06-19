# Prioritized Implementation Tasks — Bhargava

## Hack night alignment

See [hack-night-alignment.md](hack-night-alignment.md) for the official [DevOps Society hack night](https://github.com/carlyrichmond/devops-society-elastic-hack-night) checklist mapped to this project.

Quick run: `./scripts/hack-night-complete.sh`

## Hackathon sprint (1 hour, 2 people)

See [hackathon-sprint-plan.md](hackathon-sprint-plan.md) for the 30-minute block plan (Alapaty + Laxman Peri).

## Priority 1 (hack night — aligned with [official repo](https://github.com/carlyrichmond/devops-society-elastic-hack-night))

See [hack-night-alignment.md](hack-night-alignment.md) for the full checklist.

- Elastic Serverless Observability + valid mOTLP endpoint + API keys in `.env`
- `./scripts/start-demo.sh` (Docker) or `./demo.sh k8s` (official k8s path)
- `transform/logs-streams` via `config/otelcol-elastic-hacknight.yaml`
- Create `bhargava-tutor` agent with observability tools and Kibana URL in instructions
- Validate checkout trace walkthrough demo question end-to-end
- Rehearse 5-minute lightning demo with live Kibana link click

## Priority 2
- Add custom ES|QL tool `hack.slow_checkout_transactions`
- Create Agent Builder Skill with quiz question bank (referenced content)
- Document working Kibana trace URL format for deployment region
- Optional: Elastic Observability MCP + Claude Code integration

## Priority 3
- On-call copilot variant (swap tools + instructions)
- Automated traffic script before demo
- HTML export of tutoring sessions
- Integration with ArthaLedger Buyside (`ch_finance/`) as separate diligence agent

## Related monorepo

[ArthaLedger Buyside](../../README.md) at repository root (`ch_finance/`).
