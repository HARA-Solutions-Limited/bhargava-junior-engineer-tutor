# Bhargava — Junior Engineer Tutor

An Elastic Agent Builder tutor named **Bhargava** (after Lord Parasurama) that onboards junior engineers to the **OpenTelemetry Astronomy Shop** using live traces, service topology, and Kibana deep links.

Built for the [DevOps Society × Elastic London Hack Night](https://github.com/carlyrichmond/devops-society-elastic-hack-night) — see **[docs/hack-night-alignment.md](docs/hack-night-alignment.md)** for how this project satisfies the official requirements.

## Quick start

```bash
chmod +x bootstrap.sh scripts/*.sh
./bootstrap.sh

# Edit .env with Elastic Cloud credentials (see docs/hack-night-alignment.md)
./scripts/hack-night-complete.sh   # full hack night + Bhargava flow

# Or step by step:
./scripts/start-demo.sh
./scripts/create-agent.sh
./scripts/place-order.sh
open http://localhost:8080
```

## Project layout

```
bhargava-junior-engineer-tutor/
├── README.md
├── TLDR.md
├── Architecture.md
├── bootstrap.sh
├── docker-compose.yml
├── .env.example
├── agent/
│   ├── instructions.txt
│   └── bhargava-tutor-agent.json
├── scripts/
│   ├── create-agent.sh
│   ├── generate-traffic.sh
│   ├── start-demo.sh
│   ├── place-order.sh
│   ├── verify-setup.sh
│   └── hack-night-complete.sh
├── config/
│   ├── otelcol-elastic-hacknight.yaml   # collector + logs-streams processor
│   └── docker-compose.bhargava-fix.yml
└── docs/
    ├── requirements.md
    ├── hld.md
    ├── lld.md
    ├── runbook.md
    ├── implementation-tasks.md
    └── uml/
```

## Documentation

| Doc | Description |
|-----|-------------|
| [TLDR.md](TLDR.md) | One-page overview |
| [Architecture.md](Architecture.md) | C4 + reverse-engineered Astronomy Shop |
| [docs/runbook.md](docs/runbook.md) | Hack-night copy-paste spec |
| [docs/requirements.md](docs/requirements.md) | EARS requirements |
| [docs/hld.md](docs/hld.md) | High-level design |
| [docs/lld.md](docs/lld.md) | Agent tools, API, contracts |
| [docs/elastic-cloud-setup.md](docs/elastic-cloud-setup.md) | Step-by-step Elastic Cloud configuration |
| [docs/simulation-scenarios/](docs/simulation-scenarios/) | Easy / medium / hard training exercises |
| [docs/hack-night-alignment.md](docs/hack-night-alignment.md) | **Official hack night checklist mapped to Bhargava** |
| [docs/hackathon-sprint-plan.md](docs/hackathon-sprint-plan.md) | 1-hour hackathon sprint plan (2 people) |

## Demo question

> *I just clicked Place Order. Walk me through what happened using a real checkout trace from the last 30 minutes. Include Kibana links.*

## Related

[ArthaLedger Buyside](../README.md) — separate buyside diligence toolkit in this monorepo (`ch_finance/`).
